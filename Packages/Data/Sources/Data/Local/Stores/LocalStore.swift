import Foundation

public protocol LocalStore: Sendable {
    associatedtype Record: Identifiable & Sendable where Record.ID == UUID

    func fetchAll() async throws -> [Record]
    func fetch(id: UUID) async throws -> Record?
    func insert(_ record: Record) async throws
    func update(_ record: Record) async throws
    func upsert(_ record: Record) async throws
    func upsertAll(_ records: [Record]) async throws
    func delete(id: UUID) async throws
    func deleteAll() async throws
    func count() async throws -> Int
    func fetchPendingSync() async throws -> [Record]
}
