import Domain
import Foundation

public final class FetchExpensesUseCase: FetchExpensesUseCaseProtocol, @unchecked Sendable {
    private let repository: ExpenseRepositoryProtocol

    public init(repository: ExpenseRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> [Expense] {
        try await repository.fetchExpenses()
    }
}
