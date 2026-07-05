import Foundation

public enum ExpenseSyncStatus: String, Sendable, Codable, CaseIterable, Equatable {
    case synced
    case pending
    case failed
}
