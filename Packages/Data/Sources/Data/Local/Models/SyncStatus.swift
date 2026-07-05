import Foundation

public enum SyncStatus: String, Sendable, Codable, CaseIterable {
    case synced
    case pending
    case failed
}
