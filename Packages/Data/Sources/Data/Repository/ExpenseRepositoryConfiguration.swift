import Foundation

public struct ExpenseRepositoryConfiguration: Sendable {
    public let maxSyncRetries: Int
    public let attemptImmediateSyncWhenOnline: Bool
    public let autoSyncOnReconnect: Bool

    public init(
        maxSyncRetries: Int = 3,
        attemptImmediateSyncWhenOnline: Bool = true,
        autoSyncOnReconnect: Bool = true
    ) {
        self.maxSyncRetries = maxSyncRetries
        self.attemptImmediateSyncWhenOnline = attemptImmediateSyncWhenOnline
        self.autoSyncOnReconnect = autoSyncOnReconnect
    }

    public static let `default` = ExpenseRepositoryConfiguration()
}
