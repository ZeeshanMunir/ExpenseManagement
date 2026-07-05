import Foundation

public protocol ExpenseOfflineQueueProtocol: Sendable {
    func enqueue(_ item: OfflineQueueItem) async throws
    func fetchAll() async throws -> [OfflineQueueItem]
    func remove(id: UUID) async throws
    func updateRetryCount(id: UUID, retryCount: Int) async throws
    func removeOperations(forExpenseId expenseId: UUID) async throws
    func replacePendingOperation(
        expenseId: UUID,
        operation: OfflineOperationType,
        payload: Data?
    ) async throws
    func resetAllRetryCounts() async throws
    func count() async throws -> Int
}
