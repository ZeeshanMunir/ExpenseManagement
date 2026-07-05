import Core
import Domain
import Foundation

public final class ExpenseRepository: ExpenseRepositoryProtocol, @unchecked Sendable {
    private let remoteDataSource: ExpenseRemoteDataSourceProtocol
    private let localStore: any ExpenseLocalStoreProtocol
    private let offlineQueue: any ExpenseOfflineQueueProtocol
    private let reachability: any NetworkReachability
    private let configuration: ExpenseRepositoryConfiguration
    private let syncCoordinator = SyncCoordinator()

    public init(
        remoteDataSource: ExpenseRemoteDataSourceProtocol,
        localStore: any ExpenseLocalStoreProtocol,
        offlineQueue: any ExpenseOfflineQueueProtocol,
        reachability: any NetworkReachability = AlwaysConnectedReachability(),
        configuration: ExpenseRepositoryConfiguration = .default
    ) {
        self.remoteDataSource = remoteDataSource
        self.localStore = localStore
        self.offlineQueue = offlineQueue
        self.reachability = reachability
        self.configuration = configuration
    }

    // MARK: - Read (offline-first: cache is always the source for reads)

    public func fetchExpenses() async throws -> [Expense] {
        await refreshCacheIfOnline()
        let records = try await localStore.fetchAll()
        return records.map(ExpenseEntityMapper.toDomain)
    }

    public func fetchExpense(id: UUID) async throws -> Expense? {
        guard let record = try await localStore.fetch(id: id) else {
            return nil
        }
        return ExpenseEntityMapper.toDomain(record)
    }

    public func searchExpenses(criteria: ExpenseSearchCriteria) async throws -> [Expense] {
        let expenses = try await fetchExpenses()
        return expenses.filter { matches(criteria: criteria, expense: $0) }
    }

    // MARK: - Write (local-first, queue for remote sync)

    public func createExpense(_ input: CreateExpenseInput) async throws -> Expense {
        let expense = Expense(
            title: input.title,
            amount: input.amount,
            date: input.date,
            category: input.category,
            note: input.note,
            syncStatus: .pending
        )
        let record = ExpenseEntityMapper.toRecord(from: expense, syncStatus: .pending)
        let payload = try encodePayload(from: record)

        try await localStore.insert(record)
        try await offlineQueue.replacePendingOperation(
            expenseId: expense.id,
            operation: .create,
            payload: payload
        )

        await attemptImmediateSyncIfNeeded()
        return expense
    }

    public func updateExpense(_ input: UpdateExpenseInput) async throws -> Expense {
        guard let existing = try await localStore.fetch(id: input.id) else {
            throw DomainError.expenseNotFound(id: input.id)
        }

        let expense = Expense(
            id: input.id,
            title: input.title,
            amount: input.amount,
            date: input.date,
            category: input.category,
            note: input.note,
            syncStatus: .pending
        )

        let record = ExpenseRecord(
            id: expense.id,
            title: expense.title,
            amount: (expense.amount as NSDecimalNumber).doubleValue,
            date: expense.date,
            createdAt: existing.createdAt,
            updatedAt: .now,
            syncStatus: .pending
        )
        let payload = try encodePayload(from: record)

        try await localStore.update(record)
        try await offlineQueue.replacePendingOperation(
            expenseId: expense.id,
            operation: .update,
            payload: payload
        )

        await attemptImmediateSyncIfNeeded()
        return expense
    }

    public func deleteExpense(id: UUID) async throws {
        guard let existing = try await localStore.fetch(id: id) else {
            throw DomainError.expenseNotFound(id: id)
        }

        let shouldSyncDelete = existing.syncStatus == .synced || existing.syncStatus == .failed
        if shouldSyncDelete {
            // Persist the remote delete before removing local data so it can be retried.
            try await offlineQueue.replacePendingOperation(
                expenseId: id,
                operation: .delete,
                payload: nil
            )
        } else {
            try await offlineQueue.removeOperations(forExpenseId: id)
        }

        try await localStore.delete(id: id)
        await attemptImmediateSyncIfNeeded()
    }

    // MARK: - Sync

    public func syncExpenses() async throws -> SyncExpensesResult {
        try await syncCoordinator.perform {
            try await self.performSync(resetFailedRetries: false)
        }
    }

    public func retryFailedSync() async throws -> SyncExpensesResult {
        try await syncCoordinator.perform {
            try await self.performSync(resetFailedRetries: true)
        }
    }

    // MARK: - Private

    private func refreshCacheIfOnline() async {
        guard await reachability.isConnected() else { return }

        do {
            let remoteDTOs = try await remoteDataSource.fetchExpenses()
            let remoteRecords = remoteDTOs.map {
                ExpenseEntityMapper.toRecord(from: $0, syncStatus: .synced)
            }
            let localRecords = try await localStore.fetchAll()
            let merged = ExpenseConflictResolver.merge(
                remoteRecords: remoteRecords,
                localRecords: localRecords
            )
            try await localStore.upsertAll(merged)
        } catch {
            AppLogger.data.debug("Cache refresh skipped: \(error.localizedDescription)")
        }
    }

    private func performSync(resetFailedRetries: Bool) async throws -> SyncExpensesResult {
        guard await reachability.isConnected() else {
            throw DomainError.syncFailed(message: "No network connection available.")
        }

        if resetFailedRetries {
            try await prepareFailedItemsForRetry()
        }
        try await restoreOrphanedPendingRecords()

        var syncedCount = 0
        var failedCount = 0
        let queueItems = try await offlineQueue.fetchAll()

        for item in queueItems {
            if item.retryCount >= configuration.maxSyncRetries && !resetFailedRetries {
                failedCount += 1
                continue
            }

            do {
                try await processQueueItem(item)
                try await offlineQueue.remove(id: item.id)
                syncedCount += 1
            } catch {
                let nextRetry = item.retryCount + 1
                if nextRetry >= configuration.maxSyncRetries {
                    try await markExpenseAsFailed(expenseId: item.expenseId)
                } else {
                    try await offlineQueue.updateRetryCount(id: item.id, retryCount: nextRetry)
                }
                failedCount += 1
                AppLogger.data.error("Sync failed for \(item.expenseId): \(error.localizedDescription)")
            }
        }

        await refreshCacheIfOnline()
        return SyncExpensesResult(syncedCount: syncedCount, failedCount: failedCount)
    }

    private func prepareFailedItemsForRetry() async throws {
        try await offlineQueue.resetAllRetryCounts()

        let failedRecords = try await localStore.fetchFailedSync()
        for record in failedRecords {
            let pending = ExpenseRecord(
                id: record.id,
                title: record.title,
                amount: record.amount,
                date: record.date,
                createdAt: record.createdAt,
                updatedAt: record.updatedAt,
                syncStatus: .pending
            )
            try await localStore.update(pending)
        }
    }

    private func restoreOrphanedPendingRecords() async throws {
        let queueItems = try await offlineQueue.fetchAll()
        let queuedExpenseIDs = Set(queueItems.map(\.expenseId))

        let pendingRecords = try await localStore.fetchPendingSync()
        for record in pendingRecords where !queuedExpenseIDs.contains(record.id) {
            let payload = try encodePayload(from: record)
            try await offlineQueue.replacePendingOperation(
                expenseId: record.id,
                operation: .create,
                payload: payload
            )
        }

        let failedRecords = try await localStore.fetchFailedSync()
        for record in failedRecords where !queuedExpenseIDs.contains(record.id) {
            let payload = try encodePayload(from: record)
            try await offlineQueue.replacePendingOperation(
                expenseId: record.id,
                operation: .update,
                payload: payload
            )
            let pending = ExpenseRecord(
                id: record.id,
                title: record.title,
                amount: record.amount,
                date: record.date,
                createdAt: record.createdAt,
                updatedAt: record.updatedAt,
                syncStatus: .pending
            )
            try await localStore.update(pending)
        }
    }

    private func processQueueItem(_ item: OfflineQueueItem) async throws {
        switch item.operation {
        case .create:
            let record = try decodePayload(item.payload)
            try await remoteDataSource.createExpense(ExpenseEntityMapper.toDTO(record))
            try await markExpenseAsSynced(record)

        case .update:
            let record = try decodePayload(item.payload)
            try await remoteDataSource.updateExpense(ExpenseEntityMapper.toDTO(record))
            try await markExpenseAsSynced(record)

        case .delete:
            try await remoteDataSource.deleteExpense(id: item.expenseId)
        }
    }

    private func markExpenseAsSynced(_ record: ExpenseRecord) async throws {
        let synced = ExpenseRecord(
            id: record.id,
            title: record.title,
            amount: record.amount,
            date: record.date,
            createdAt: record.createdAt,
            updatedAt: .now,
            syncStatus: .synced
        )
        try await localStore.upsert(synced)
    }

    private func markExpenseAsFailed(expenseId: UUID) async throws {
        guard let record = try await localStore.fetch(id: expenseId) else { return }
        let failed = ExpenseRecord(
            id: record.id,
            title: record.title,
            amount: record.amount,
            date: record.date,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt,
            syncStatus: .failed
        )
        try await localStore.update(failed)
    }

    private func attemptImmediateSyncIfNeeded() async {
        guard configuration.attemptImmediateSyncWhenOnline else { return }
        guard await reachability.isConnected() else { return }

        do {
            _ = try await syncExpenses()
        } catch {
            AppLogger.data.debug("Immediate sync deferred: \(error.localizedDescription)")
        }
    }

    private func encodePayload(from record: ExpenseRecord) throws -> Data {
        let dto = ExpenseEntityMapper.toDTO(record)
        return try JSONCoding.makeEncoder().encode(dto)
    }

    private func decodePayload(_ payload: Data?) throws -> ExpenseRecord {
        guard let payload else { throw PersistenceError.mappingFailed }
        let dto = try JSONCoding.makeDecoder().decode(ExpenseDTO.self, from: payload)
        return ExpenseEntityMapper.toRecord(from: dto, syncStatus: .pending)
    }

    private func matches(criteria: ExpenseSearchCriteria, expense: Expense) -> Bool {
        let matchesQuery = criteria.query.isEmpty
            || expense.title.localizedCaseInsensitiveContains(criteria.query)
            || (expense.note?.localizedCaseInsensitiveContains(criteria.query) ?? false)

        let matchesStartDate = criteria.startDate.map { expense.date >= $0 } ?? true
        let matchesEndDate = criteria.endDate.map { expense.date <= $0 } ?? true
        let matchesMinAmount = criteria.minAmount.map { expense.amount >= $0 } ?? true
        let matchesMaxAmount = criteria.maxAmount.map { expense.amount <= $0 } ?? true
        let matchesCategory = criteria.category.map { expense.category == $0 } ?? true

        return matchesQuery
            && matchesStartDate
            && matchesEndDate
            && matchesMinAmount
            && matchesMaxAmount
            && matchesCategory
    }
}

// MARK: - Sync Serialization

private actor SyncCoordinator {
    func perform<T: Sendable>(_ operation: @Sendable () async throws -> T) async throws -> T {
        try await operation()
    }
}
