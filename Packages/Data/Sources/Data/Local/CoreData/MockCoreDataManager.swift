import CoreData
import Foundation

public final class MockCoreDataManager: CoreDataManaging, @unchecked Sendable {
    public let container: NSPersistentContainer

    public init(inMemory: Bool = true) {
        let manager = CoreDataManager(inMemory: inMemory)
        container = manager.container
    }

    public var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    @discardableResult
    public func performBackgroundTask<T: Sendable>(
        _ block: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        let context = container.newBackgroundContext()
        return try await context.performAsync { context in
            let result = try block(context)
            if context.hasChanges {
                try context.save()
            }
            return result
        }
    }

    public func save(_ context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }
        try context.save()
    }
}
