import Foundation

public enum ExpenseConflictResolver {
    /// Resolves a conflict between a local cached record and a remote record.
    /// Pending local changes always win. Otherwise, the most recently updated record wins.
    public static func resolve(local: ExpenseRecord, remote: ExpenseRecord) -> ExpenseRecord {
        if local.syncStatus == .pending || local.syncStatus == .failed {
            return local
        }

        if remote.updatedAt > local.updatedAt {
            return remote.markingSynced()
        }

        return local.markingSynced()
    }

    /// Merges remote records into the local cache applying conflict resolution rules.
    public static func merge(
        remoteRecords: [ExpenseRecord],
        localRecords: [ExpenseRecord]
    ) -> [ExpenseRecord] {
        let localByID = Dictionary(uniqueKeysWithValues: localRecords.map { ($0.id, $0) })
        var merged: [ExpenseRecord] = []
        var processedIDs = Set<UUID>()

        for remote in remoteRecords {
            processedIDs.insert(remote.id)
            if let local = localByID[remote.id] {
                merged.append(resolve(local: local, remote: remote))
            } else {
                merged.append(remote.markingSynced())
            }
        }

        for local in localRecords where !processedIDs.contains(local.id) {
            merged.append(local)
        }

        return merged.sorted { $0.date > $1.date }
    }
}

private extension ExpenseRecord {
    func markingSynced() -> ExpenseRecord {
        ExpenseRecord(
            id: id,
            title: title,
            amount: amount,
            date: date,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: .synced
        )
    }
}
