import Foundation

public enum DomainError: Error, LocalizedError, Equatable, Sendable {
    case invalidTitle
    case invalidAmount
    case expenseNotFound(id: UUID)
    case syncFailed(message: String)

    public var errorDescription: String? {
        switch self {
        case .invalidTitle:
            return "Expense title cannot be empty."
        case .invalidAmount:
            return "Expense amount must be greater than zero."
        case .expenseNotFound(let id):
            return "Expense not found for id: \(id)"
        case .syncFailed(let message):
            return "Sync failed: \(message)"
        }
    }
}
