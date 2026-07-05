import Domain
import Foundation

public final class SyncExpensesUseCase: SyncExpensesUseCaseProtocol, @unchecked Sendable {
    private let repository: ExpenseRepositoryProtocol

    public init(repository: ExpenseRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> SyncExpensesResult {
        try await repository.syncExpenses()
    }
}
