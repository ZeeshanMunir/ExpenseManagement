import Foundation

public enum ExpenseCategory: String, CaseIterable, Codable, Sendable {
    case food
    case transport
    case shopping
    case entertainment
    case bills
    case health
    case travel
    case other
}
