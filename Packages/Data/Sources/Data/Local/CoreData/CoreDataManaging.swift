import CoreData
import Foundation

public protocol CoreDataManaging: Sendable {
    var viewContext: NSManagedObjectContext { get }

    @discardableResult
    func performBackgroundTask<T: Sendable>(
        _ block: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async throws -> T

    func save(_ context: NSManagedObjectContext) throws
}
