import Core
import CoreData
import Foundation

public final class CoreDataManager: CoreDataManaging, @unchecked Sendable {
    public static let shared = CoreDataManager()

    public let container: NSPersistentContainer

    public init(
        modelName: String = AppConstants.coreDataModelName,
        inMemory: Bool = false,
        bundle: Bundle? = nil
    ) {
        let resolvedBundle = bundle ?? Bundle.module

        if let modelURL = resolvedBundle.url(forResource: modelName, withExtension: "momd"),
           let model = NSManagedObjectModel(contentsOf: modelURL) {
            container = NSPersistentContainer(name: modelName, managedObjectModel: model)
        } else {
            container = NSPersistentContainer(name: modelName)
        }

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [description]
        }

        var loadError: Error?
        let semaphore = DispatchSemaphore(value: 0)

        container.loadPersistentStores { _, error in
            loadError = error
            semaphore.signal()
        }

        semaphore.wait()

        if let loadError {
            AppLogger.data.error("Core Data store failed to load: \(loadError.localizedDescription)")
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
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
                try self.save(context)
            }
            return result
        }
    }

    public func save(_ context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            throw PersistenceError.saveFailed(message: error.localizedDescription)
        }
    }
}

public typealias CoreDataStack = CoreDataManager
