import Foundation

public struct ExpenseSearchCriteria: Equatable, Sendable {
    public let query: String
    public let startDate: Date?
    public let endDate: Date?
    public let minAmount: Decimal?
    public let maxAmount: Decimal?
    public let category: ExpenseCategory?

    public init(
        query: String = "",
        startDate: Date? = nil,
        endDate: Date? = nil,
        minAmount: Decimal? = nil,
        maxAmount: Decimal? = nil,
        category: ExpenseCategory? = nil
    ) {
        self.query = query
        self.startDate = startDate
        self.endDate = endDate
        self.minAmount = minAmount
        self.maxAmount = maxAmount
        self.category = category
    }
}
