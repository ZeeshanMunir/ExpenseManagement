import CoreData
import Foundation

enum OfflineQueueMapper {
    static func toItem(_ entity: OfflineQueueEntity) -> OfflineQueueItem? {
        guard let id = entity.id,
              let expenseId = entity.expenseId,
              let operationRaw = entity.operationType,
              let operation = OfflineOperationType(rawValue: operationRaw),
              let createdAt = entity.createdAt else {
            return nil
        }

        return OfflineQueueItem(
            id: id,
            expenseId: expenseId,
            operation: operation,
            payload: entity.payload,
            createdAt: createdAt,
            retryCount: Int(entity.retryCount)
        )
    }

    static func update(_ entity: OfflineQueueEntity, from item: OfflineQueueItem) {
        entity.id = item.id
        entity.expenseId = item.expenseId
        entity.operationType = item.operation.rawValue
        entity.payload = item.payload
        entity.createdAt = item.createdAt
        entity.retryCount = Int32(item.retryCount)
    }
}

public final class ExpenseOfflineQueue: ExpenseOfflineQueueProtocol, @unchecked Sendable {
    private let coreDataManager: any CoreDataManaging

    public init(coreDataManager: any CoreDataManaging) {
        self.coreDataManager = coreDataManager
    }

    public func enqueue(_ item: OfflineQueueItem) async throws {
        try await coreDataManager.performBackgroundTask { context in
            let entity = OfflineQueueEntity(context: context)
            OfflineQueueMapper.update(entity, from: item)
        }
    }

    public func fetchAll() async throws -> [OfflineQueueItem] {
        try await coreDataManager.performBackgroundTask { context in
            let request = OfflineQueueEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            let entities = try context.fetch(request)
            return entities.compactMap(OfflineQueueMapper.toItem)
        }
    }

    public func remove(id: UUID) async throws {
        try await coreDataManager.performBackgroundTask { context in
            guard let entity = try Self.fetchEntity(id: id, in: context) else { return }
            context.delete(entity)
        }
    }

    public func updateRetryCount(id: UUID, retryCount: Int) async throws {
        try await coreDataManager.performBackgroundTask { context in
            guard let entity = try Self.fetchEntity(id: id, in: context) else { return }
            entity.retryCount = Int32(retryCount)
        }
    }

    public func removeOperations(forExpenseId expenseId: UUID) async throws {
        try await coreDataManager.performBackgroundTask { context in
            let request = OfflineQueueEntity.fetchRequest()
            request.predicate = NSPredicate(format: "expenseId == %@", expenseId as CVarArg)
            let entities = try context.fetch(request)
            entities.forEach { context.delete($0) }
        }
    }

    public func replacePendingOperation(
        expenseId: UUID,
        operation: OfflineOperationType,
        payload: Data?
    ) async throws {
        try await removeOperations(forExpenseId: expenseId)
        try await enqueue(
            OfflineQueueItem(
                expenseId: expenseId,
                operation: operation,
                payload: payload
            )
        )
    }

    public func resetAllRetryCounts() async throws {
        try await coreDataManager.performBackgroundTask { context in
            let request = OfflineQueueEntity.fetchRequest()
            let entities = try context.fetch(request)
            entities.forEach { $0.retryCount = 0 }
        }
    }

    public func count() async throws -> Int {
        try await coreDataManager.performBackgroundTask { context in
            let request = OfflineQueueEntity.fetchRequest()
            return try context.count(for: request)
        }
    }

    private static func fetchEntity(id: UUID, in context: NSManagedObjectContext) throws -> OfflineQueueEntity? {
        let request = OfflineQueueEntity.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try context.fetch(request).first
    }
}
