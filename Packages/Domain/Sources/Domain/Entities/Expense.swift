import Foundation

public struct Expense: Identifiable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let amount: Decimal
    public let date: Date
    public let category: ExpenseCategory?
    public let note: String?
    public let syncStatus: ExpenseSyncStatus

    public init(
        id: UUID = UUID(),
        title: String,
        amount: Decimal,
        date: Date,
        category: ExpenseCategory? = nil,
        note: String? = nil,
        syncStatus: ExpenseSyncStatus = .synced
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.category = category
        self.note = note
        self.syncStatus = syncStatus
    }
}
