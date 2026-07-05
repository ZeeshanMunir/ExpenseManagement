import Foundation

public enum OfflineOperationType: String, Codable, Sendable, CaseIterable {
    case create
    case update
    case delete
}
