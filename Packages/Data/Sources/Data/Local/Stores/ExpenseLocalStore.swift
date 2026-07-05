import CoreData
import Foundation

public protocol ExpenseLocalStoreProtocol: LocalStore where Record == ExpenseRecord {
    func fetchPendingSync() async throws -> [ExpenseRecord]
    func fetchFailedSync() async throws -> [ExpenseRecord]
}

public final class ExpenseLocalStore: ExpenseLocalStoreProtocol, @unchecked Sendable {
    private let coreDataManager: any CoreDataManaging

    public init(coreDataManager: any CoreDataManaging) {
        self.coreDataManager = coreDataManager
    }

    public func fetchAll() async throws -> [ExpenseRecord] {
        try await coreDataManager.performBackgroundTask { context in
            let request = ExpenseEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            let entities = try context.fetch(request)
            return entities.compactMap(ExpenseEntityMapper.toRecord)
        }
    }

    public func fetch(id: UUID) async throws -> ExpenseRecord? {
        try await coreDataManager.performBackgroundTask { context in
            guard let entity = try Self.fetchEntity(id: id, in: context) else {
                return nil
            }
            return ExpenseEntityMapper.toRecord(entity)
        }
    }

    public func insert(_ record: ExpenseRecord) async throws {
        try await coreDataManager.performBackgroundTask { context in
            if try Self.fetchEntity(id: record.id, in: context) != nil {
                throw PersistenceError.saveFailed(message: "Record already exists for id: \(record.id)")
            }
            let entity = ExpenseEntity(context: context)
            ExpenseEntityMapper.update(entity, from: record)
        }
    }

    public func update(_ record: ExpenseRecord) async throws {
        try await coreDataManager.performBackgroundTask { context in
            guard let entity = try Self.fetchEntity(id: record.id, in: context) else {
                throw PersistenceError.notFound(id: record.id)
            }
            ExpenseEntityMapper.update(entity, from: record)
        }
    }

    public func upsert(_ record: ExpenseRecord) async throws {
        try await coreDataManager.performBackgroundTask { context in
            let entity = try Self.fetchEntity(id: record.id, in: context) ?? ExpenseEntity(context: context)
            ExpenseEntityMapper.update(entity, from: record)
        }
    }

    public func upsertAll(_ records: [ExpenseRecord]) async throws {
        try await coreDataManager.performBackgroundTask { context in
            for record in records {
                let entity = try Self.fetchEntity(id: record.id, in: context) ?? ExpenseEntity(context: context)
                ExpenseEntityMapper.update(entity, from: record)
            }
        }
    }

    public func delete(id: UUID) async throws {
        try await coreDataManager.performBackgroundTask { context in
            guard let entity = try Self.fetchEntity(id: id, in: context) else {
                throw PersistenceError.notFound(id: id)
            }
            context.delete(entity)
        }
    }

    public func deleteAll() async throws {
        try await coreDataManager.performBackgroundTask { context in
            let request = ExpenseEntity.fetchRequest()
            let entities = try context.fetch(request)
            entities.forEach { context.delete($0) }
        }
    }

    public func count() async throws -> Int {
        try await coreDataManager.performBackgroundTask { context in
            let request = ExpenseEntity.fetchRequest()
            return try context.count(for: request)
        }
    }

    public func fetchPendingSync() async throws -> [ExpenseRecord] {
        try await coreDataManager.performBackgroundTask { context in
            let request = ExpenseEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "syncStatus == %@",
                SyncStatus.pending.rawValue
            )
            request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: true)]
            let entities = try context.fetch(request)
            return entities.compactMap(ExpenseEntityMapper.toRecord)
        }
    }

    public func fetchFailedSync() async throws -> [ExpenseRecord] {
        try await coreDataManager.performBackgroundTask { context in
            let request = ExpenseEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "syncStatus == %@",
                SyncStatus.failed.rawValue
            )
            request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: true)]
            let entities = try context.fetch(request)
            return entities.compactMap(ExpenseEntityMapper.toRecord)
        }
    }

    private static func fetchEntity(id: UUID, in context: NSManagedObjectContext) throws -> ExpenseEntity? {
        let request = ExpenseEntity.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try context.fetch(request).first
    }
}
