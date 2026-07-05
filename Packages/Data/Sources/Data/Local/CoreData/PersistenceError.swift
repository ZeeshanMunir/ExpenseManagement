import Foundation

public enum PersistenceError: Error, LocalizedError, Equatable, Sendable {
    case storeLoadFailed(message: String)
    case saveFailed(message: String)
    case fetchFailed(message: String)
    case deleteFailed(message: String)
    case notFound(id: UUID)
    case mappingFailed
    case invalidContext

    public var errorDescription: String? {
        switch self {
        case .storeLoadFailed(let message):
            return "Failed to load persistent store: \(message)"
        case .saveFailed(let message):
            return "Failed to save context: \(message)"
        case .fetchFailed(let message):
            return "Failed to fetch data: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete data: \(message)"
        case .notFound(let id):
            return "Record not found for id: \(id)"
        case .mappingFailed:
            return "Failed to map between entity and record."
        case .invalidContext:
            return "The managed object context is invalid."
        }
    }

    public static func map(_ error: Error) -> PersistenceError {
        if let persistenceError = error as? PersistenceError {
            return persistenceError
        }
        return .saveFailed(message: error.localizedDescription)
    }
}
