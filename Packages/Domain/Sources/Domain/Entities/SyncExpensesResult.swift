import Foundation

public struct SyncExpensesResult: Equatable, Sendable {
    public let syncedCount: Int
    public let failedCount: Int

    public init(syncedCount: Int, failedCount: Int) {
        self.syncedCount = syncedCount
        self.failedCount = failedCount
    }
}
