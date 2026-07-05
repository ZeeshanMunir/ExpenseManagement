import Domain
import Foundation

extension SyncStatus {
    func toDomain() -> ExpenseSyncStatus {
        switch self {
        case .synced: .synced
        case .pending: .pending
        case .failed: .failed
        }
    }
}

extension ExpenseSyncStatus {
    func toData() -> SyncStatus {
        switch self {
        case .synced: .synced
        case .pending: .pending
        case .failed: .failed
        }
    }
}
