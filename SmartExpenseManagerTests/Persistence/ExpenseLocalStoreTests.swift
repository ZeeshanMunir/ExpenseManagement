import Data
import Foundation
import Testing

struct ExpenseLocalStoreTests {
    @Test func insertAndFetchExpense() async throws {
        let manager = MockCoreDataManager()
        let store = ExpenseLocalStore(coreDataManager: manager)

        let record = ExpenseRecord(
            title: "Coffee",
            amount: 4.5,
            date: .now,
            syncStatus: .pending
        )

        try await store.insert(record)
        let fetched = try await store.fetch(id: record.id)

        #expect(fetched?.title == "Coffee")
        #expect(fetched?.amount == 4.5)
        #expect(fetched?.syncStatus == .pending)
    }

    @Test func upsertUpdatesExistingRecord() async throws {
        let manager = MockCoreDataManager()
        let store = ExpenseLocalStore(coreDataManager: manager)

        let original = ExpenseRecord(title: "Lunch", amount: 10, date: .now)
        try await store.insert(original)

        let updated = ExpenseRecord(
            id: original.id,
            title: "Lunch Updated",
            amount: 12,
            date: original.date,
            createdAt: original.createdAt,
            updatedAt: .now,
            syncStatus: .synced
        )

        try await store.upsert(updated)
        let fetched = try await store.fetch(id: original.id)

        #expect(fetched?.title == "Lunch Updated")
        #expect(fetched?.syncStatus == .synced)
    }

    @Test func deleteRemovesRecord() async throws {
        let manager = MockCoreDataManager()
        let store = ExpenseLocalStore(coreDataManager: manager)

        let record = ExpenseRecord(title: "Taxi", amount: 20, date: .now)
        try await store.insert(record)
        try await store.delete(id: record.id)

        let fetched = try await store.fetch(id: record.id)
        #expect(fetched == nil)
    }

    @Test func fetchPendingSyncReturnsOnlyPendingRecords() async throws {
        let manager = MockCoreDataManager()
        let store = ExpenseLocalStore(coreDataManager: manager)

        try await store.insert(ExpenseRecord(title: "Pending", amount: 1, date: .now, syncStatus: .pending))
        try await store.insert(ExpenseRecord(title: "Synced", amount: 2, date: .now, syncStatus: .synced))

        let pending = try await store.fetchPendingSync()

        #expect(pending.count == 1)
        #expect(pending.first?.title == "Pending")
    }

    @Test func fetchAllReturnsSortedRecords() async throws {
        let manager = MockCoreDataManager()
        let store = ExpenseLocalStore(coreDataManager: manager)

        let older = ExpenseRecord(title: "Older", amount: 1, date: .now.addingTimeInterval(-3600))
        let newer = ExpenseRecord(title: "Newer", amount: 2, date: .now)

        try await store.insert(older)
        try await store.insert(newer)

        let all = try await store.fetchAll()

        #expect(all.count == 2)
        #expect(all.first?.title == "Newer")
    }
}
