import Core
import Data
import Domain
import XCTest

final class ExpenseRepositoryTests: XCTestCase {
  // MARK: - Create

  func testCreateExpenseWritesToLocalStoreAndQueue() async throws {
    let (repository, localStore, offlineQueue, _) = RepositoryTestDoubles.makeRepository(
      remote: RepositoryTestDoubles.MockExpenseRemoteDataSource(),
      reachability: AlwaysConnectedReachability()
    )

    let input = CreateExpenseInput(title: "Coffee", amount: 4.5, date: .now)
    let expense = try await repository.createExpense(input)

    let cached = try await localStore.fetch(id: expense.id)
    let queue = try await offlineQueue.fetchAll()

    XCTAssertEqual(cached?.title, "Coffee")
    XCTAssertEqual(cached?.syncStatus, .pending)
    XCTAssertEqual(queue.count, 1)
    XCTAssertEqual(queue.first?.operation, .create)
  }

  // MARK: - Read

  func testFetchExpensesReturnsLocalCacheWhenOffline() async throws {
    let (repository, localStore, _, _) = RepositoryTestDoubles.makeRepository(
      remote: RepositoryTestDoubles.FailingExpenseRemoteDataSource(),
      reachability: RepositoryTestDoubles.OfflineReachability()
    )

    try await localStore.insert(
      ExpenseRecord(title: "Cached", amount: 12, date: .now, syncStatus: .synced)
    )

    let expenses = try await repository.fetchExpenses()

    XCTAssertEqual(expenses.count, 1)
    XCTAssertEqual(expenses.first?.title, "Cached")
  }

  func testFetchExpenseReturnsSingleCachedRecord() async throws {
    let (repository, localStore, _, _) = RepositoryTestDoubles.makeRepository(
      remote: RepositoryTestDoubles.FailingExpenseRemoteDataSource(),
      reachability: RepositoryTestDoubles.OfflineReachability()
    )
    let record = ExpenseRecord(title: "Detail", amount: 8, date: .now, syncStatus: .synced)
    try await localStore.insert(record)

    let expense = try await repository.fetchExpense(id: record.id)

    XCTAssertEqual(expense?.title, "Detail")
  }

  // MARK: - Update

  func testUpdateExpenseWritesPendingRecordAndQueuesUpdate() async throws {
    let (repository, localStore, offlineQueue, _) = RepositoryTestDoubles.makeRepository(
      remote: RepositoryTestDoubles.MockExpenseRemoteDataSource(),
      reachability: AlwaysConnectedReachability()
    )
    let created = try await repository.createExpense(
      CreateExpenseInput(title: "Original", amount: 10, date: .now)
    )

    let updated = try await repository.updateExpense(
      UpdateExpenseInput(id: created.id, title: "Revised", amount: 15, date: created.date)
    )

    let cached = try await localStore.fetch(id: created.id)
    let queue = try await offlineQueue.fetchAll()

    XCTAssertEqual(updated.title, "Revised")
    XCTAssertEqual(cached?.syncStatus, .pending)
    XCTAssertEqual(queue.count, 1)
    XCTAssertEqual(queue.first?.operation, .update)
  }

  // MARK: - Delete

  func testDeleteSyncedExpenseQueuesDeleteBeforeLocalRemoval() async throws {
    let (repository, localStore, offlineQueue, _) = RepositoryTestDoubles.makeRepository(
      remote: RepositoryTestDoubles.MockExpenseRemoteDataSource(),
      reachability: RepositoryTestDoubles.OfflineReachability()
    )
    let expenseID = UUID()
    try await localStore.insert(
      ExpenseRecord(id: expenseID, title: "Synced", amount: 10, date: .now, syncStatus: .synced)
    )

    try await repository.deleteExpense(id: expenseID)

    let queue = try await offlineQueue.fetchAll()
    let cached = try await localStore.fetch(id: expenseID)

    XCTAssertEqual(queue.count, 1)
    XCTAssertEqual(queue.first?.operation, .delete)
    XCTAssertEqual(queue.first?.expenseId, expenseID)
    XCTAssertNil(cached)
  }

  func testDeletePendingExpenseRemovesLocalAndQueueWithoutRemoteDelete() async throws {
    let (repository, localStore, offlineQueue, _) = RepositoryTestDoubles.makeRepository(
      remote: RepositoryTestDoubles.MockExpenseRemoteDataSource(),
      reachability: AlwaysConnectedReachability()
    )
    let created = try await repository.createExpense(
      CreateExpenseInput(title: "Never Synced", amount: 6, date: .now)
    )

    try await repository.deleteExpense(id: created.id)

    let queue = try await offlineQueue.fetchAll()
    let cached = try await localStore.fetch(id: created.id)

    XCTAssertTrue(queue.isEmpty)
    XCTAssertNil(cached)
  }

  // MARK: - Search

  func testSearchExpensesFiltersByTitle() async throws {
    let (repository, localStore, _, _) = RepositoryTestDoubles.makeRepository(
      remote: RepositoryTestDoubles.FailingExpenseRemoteDataSource(),
      reachability: RepositoryTestDoubles.OfflineReachability()
    )
    try await localStore.insert(ExpenseRecord(title: "Coffee", amount: 4, date: .now, syncStatus: .synced))
    try await localStore.insert(ExpenseRecord(title: "Rent", amount: 900, date: .now, syncStatus: .synced))

    let results = try await repository.searchExpenses(criteria: ExpenseSearchCriteria(query: "coffee"))

    XCTAssertEqual(results.count, 1)
    XCTAssertEqual(results.first?.title, "Coffee")
  }

  // MARK: - Sync

  func testSyncPreservesQueueItemAfterMaxRetries() async throws {
    let (repository, localStore, offlineQueue, _) = RepositoryTestDoubles.makeRepository(
      remote: RepositoryTestDoubles.FailingExpenseRemoteDataSource(),
      reachability: AlwaysConnectedReachability(),
      maxSyncRetries: 1
    )

    let expense = try await repository.createExpense(
      CreateExpenseInput(title: "Offline", amount: 9.99, date: .now)
    )

    _ = try await repository.syncExpenses()

    let queue = try await offlineQueue.fetchAll()
    let cached = try await localStore.fetch(id: expense.id)

    XCTAssertEqual(queue.count, 1)
    XCTAssertEqual(cached?.syncStatus, .failed)
  }

  func testRetryFailedSyncResetsAndProcessesQueue() async throws {
    let manager = MockCoreDataManager()
    let localStore = ExpenseLocalStore(coreDataManager: manager)
    let offlineQueue = ExpenseOfflineQueue(coreDataManager: manager)
    let remote = RepositoryTestDoubles.ConditionalExpenseRemoteDataSource()
    let repository = ExpenseRepository(
      remoteDataSource: remote,
      localStore: localStore,
      offlineQueue: offlineQueue,
      reachability: AlwaysConnectedReachability(),
      configuration: ExpenseRepositoryConfiguration(maxSyncRetries: 1, attemptImmediateSyncWhenOnline: false)
    )

    let expense = try await repository.createExpense(
      CreateExpenseInput(title: "Retry Me", amount: 5, date: .now)
    )

    _ = try await repository.syncExpenses()
    let statusAfterSync = try await localStore.fetch(id: expense.id)?.syncStatus
    XCTAssertEqual(statusAfterSync, .failed)

    remote.shouldSucceed = true
    let result = try await repository.retryFailedSync()

    let cached = try await localStore.fetch(id: expense.id)
    let queue = try await offlineQueue.fetchAll()

    XCTAssertEqual(result.syncedCount, 1)
    XCTAssertEqual(cached?.syncStatus, .synced)
    XCTAssertTrue(queue.isEmpty)
  }

  func testOrphanedPendingRecordIsRestoredToQueueOnSync() async throws {
    let (repository, localStore, offlineQueue, _) = RepositoryTestDoubles.makeRepository(
      remote: RepositoryTestDoubles.FailingExpenseRemoteDataSource(),
      reachability: AlwaysConnectedReachability()
    )
    let record = ExpenseRecord(title: "Orphan", amount: 3, date: .now, syncStatus: .pending)
    try await localStore.insert(record)

    _ = try await repository.syncExpenses()

    let queue = try await offlineQueue.fetchAll()

    XCTAssertEqual(queue.count, 1)
    XCTAssertEqual(queue.first?.expenseId, record.id)
    XCTAssertEqual(queue.first?.operation, .create)
  }

  func testSyncThrowsWhenOffline() async {
    let (repository, _, _, _) = RepositoryTestDoubles.makeRepository(
      remote: RepositoryTestDoubles.MockExpenseRemoteDataSource(),
      reachability: RepositoryTestDoubles.OfflineReachability()
    )

    do {
      _ = try await repository.syncExpenses()
      XCTFail("Expected sync to throw when offline")
    } catch {
      XCTAssertEqual(error as? DomainError, .syncFailed(message: "No network connection available."))
    }
  }
}

final class ExpenseConflictResolverTests: XCTestCase {
  func testPendingLocalRecordWinsOverRemote() {
    let local = ExpenseRecord(
      id: UUID(),
      title: "Local Edit",
      amount: 10,
      date: .now,
      createdAt: .now.addingTimeInterval(-100),
      updatedAt: .now,
      syncStatus: .pending
    )
    let remote = ExpenseRecord(
      id: local.id,
      title: "Remote",
      amount: 20,
      date: .now,
      createdAt: .now,
      updatedAt: .now.addingTimeInterval(100),
      syncStatus: .synced
    )

    let resolved = ExpenseConflictResolver.resolve(local: local, remote: remote)

    XCTAssertEqual(resolved.title, "Local Edit")
  }

  func testNewerRemoteRecordWinsWhenLocalIsSynced() {
    let local = ExpenseRecord(
      id: UUID(),
      title: "Local",
      amount: 10,
      date: .now,
      createdAt: .now,
      updatedAt: .now.addingTimeInterval(-100),
      syncStatus: .synced
    )
    let remote = ExpenseRecord(
      id: local.id,
      title: "Remote",
      amount: 20,
      date: .now,
      createdAt: .now,
      updatedAt: .now,
      syncStatus: .synced
    )

    let resolved = ExpenseConflictResolver.resolve(local: local, remote: remote)

    XCTAssertEqual(resolved.title, "Remote")
  }

  func testMergePreservesLocalOnlyRecords() {
    let localOnly = ExpenseRecord(title: "Offline Only", amount: 5, date: .now, syncStatus: .pending)
    let merged = ExpenseConflictResolver.merge(remoteRecords: [], localRecords: [localOnly])

    XCTAssertEqual(merged.count, 1)
    XCTAssertEqual(merged.first?.title, "Offline Only")
  }
}

final class ExpenseSyncCoordinatorTests: XCTestCase {
  func testAutoSyncRunsWhenNetworkReconnects() async throws {
    let manager = MockCoreDataManager()
    let localStore = ExpenseLocalStore(coreDataManager: manager)
    let offlineQueue = ExpenseOfflineQueue(coreDataManager: manager)
    let remote = RepositoryTestDoubles.ConditionalExpenseRemoteDataSource()
    let reachability = RepositoryTestDoubles.ReconnectingReachability(initiallyConnected: false)

    let repository = ExpenseRepository(
      remoteDataSource: remote,
      localStore: localStore,
      offlineQueue: offlineQueue,
      reachability: reachability,
      configuration: ExpenseRepositoryConfiguration(
        attemptImmediateSyncWhenOnline: false,
        autoSyncOnReconnect: true
      )
    )
    let coordinator = ExpenseSyncCoordinator(
      repository: repository,
      reachability: reachability,
      configuration: ExpenseRepositoryConfiguration(autoSyncOnReconnect: true)
    )

    let expense = try await repository.createExpense(
      CreateExpenseInput(title: "Offline Create", amount: 7, date: .now)
    )
    let statusBeforeReconnect = try await localStore.fetch(id: expense.id)?.syncStatus
    XCTAssertEqual(statusBeforeReconnect, .pending)

    await coordinator.startAutoSync()
    remote.shouldSucceed = true
    reachability.reconnect()

    try await Task.sleep(nanoseconds: 200_000_000)

    let cached = try await localStore.fetch(id: expense.id)
    let queue = try await offlineQueue.fetchAll()

    XCTAssertEqual(cached?.syncStatus, .synced)
    XCTAssertTrue(queue.isEmpty)

    await coordinator.stopAutoSync()
  }
}
