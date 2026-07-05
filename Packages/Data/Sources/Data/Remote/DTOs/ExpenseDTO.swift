import Foundation

public struct ExpenseDTO: Codable, Sendable {
    public let id: UUID
    public let title: String
    public let amount: Double
    public let date: Date
    public let updatedAt: Date?

    public init(
        id: UUID,
        title: String,
        amount: Double,
        date: Date,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.updatedAt = updatedAt
    }
}

struct ExpenseListResponse: Codable, Sendable {
    let expenses: [ExpenseDTO]
}
