import Foundation

public struct OfflineQueueItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let expenseId: UUID
    public let operation: OfflineOperationType
    public let payload: Data?
    public let createdAt: Date
    public let retryCount: Int

    public init(
        id: UUID = UUID(),
        expenseId: UUID,
        operation: OfflineOperationType,
        payload: Data? = nil,
        createdAt: Date = .now,
        retryCount: Int = 0
    ) {
        self.id = id
        self.expenseId = expenseId
        self.operation = operation
        self.payload = payload
        self.createdAt = createdAt
        self.retryCount = retryCount
    }
}
