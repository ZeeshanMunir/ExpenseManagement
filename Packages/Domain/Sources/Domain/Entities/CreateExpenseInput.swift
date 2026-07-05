import Foundation

public struct CreateExpenseInput: Equatable, Sendable {
    public let title: String
    public let amount: Decimal
    public let date: Date
    public let category: ExpenseCategory?
    public let note: String?

    public init(
        title: String,
        amount: Decimal,
        date: Date,
        category: ExpenseCategory? = nil,
        note: String? = nil
    ) {
        self.title = title
        self.amount = amount
        self.date = date
        self.category = category
        self.note = note
    }
}
