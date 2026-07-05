import Core
import Foundation

public protocol ExpenseRemoteDataSourceProtocol: Sendable {
    func fetchExpenses() async throws -> [ExpenseDTO]
    func createExpense(_ expense: ExpenseDTO) async throws
    func updateExpense(_ expense: ExpenseDTO) async throws
    func deleteExpense(id: UUID) async throws
}

public final class ExpenseRemoteDataSource: ExpenseRemoteDataSourceProtocol, @unchecked Sendable {
    private let networkClient: NetworkClientProtocol

    public init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    public func fetchExpenses() async throws -> [ExpenseDTO] {
        let response = try await networkClient.request(
            ExpenseEndpoint.fetchAll,
            responseType: ExpenseListResponse.self
        )
        return response.expenses
    }

    public func createExpense(_ expense: ExpenseDTO) async throws {
        try await networkClient.request(ExpenseEndpoint.create(expense))
    }

    public func updateExpense(_ expense: ExpenseDTO) async throws {
        try await networkClient.request(ExpenseEndpoint.update(expense))
    }

    public func deleteExpense(id: UUID) async throws {
        try await networkClient.request(ExpenseEndpoint.delete(id: id))
    }
}
