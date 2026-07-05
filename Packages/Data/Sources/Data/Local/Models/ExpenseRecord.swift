import Foundation

public struct ExpenseRecord: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let amount: Double
    public let date: Date
    public let createdAt: Date
    public let updatedAt: Date
    public let syncStatus: SyncStatus

    public init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        date: Date,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        syncStatus: SyncStatus = .pending
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus
    }
}
