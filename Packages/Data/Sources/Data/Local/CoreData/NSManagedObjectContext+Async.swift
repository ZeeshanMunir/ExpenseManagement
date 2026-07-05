import CoreData
import Foundation

extension NSManagedObjectContext {
    func performAsync<T: Sendable>(_ block: @escaping @Sendable (NSManagedObjectContext) throws -> T) async throws -> T {
        if concurrencyType == .mainQueueConcurrencyType {
            return try await MainActor.run {
                try block(self)
            }
        }

        return try await withCheckedThrowingContinuation { continuation in
            perform {
                do {
                    let result = try block(self)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
