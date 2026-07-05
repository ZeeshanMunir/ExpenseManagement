import Foundation

public struct UpdateExpenseInput: Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let amount: Decimal
    public let date: Date
    public let category: ExpenseCategory?
    public let note: String?

    public init(
        id: UUID,
        title: String,
        amount: Decimal,
        date: Date,
        category: ExpenseCategory? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.category = category
        self.note = note
    }
}
