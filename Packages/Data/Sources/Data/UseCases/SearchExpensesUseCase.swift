import Domain
import Foundation

public final class SearchExpensesUseCase: SearchExpensesUseCaseProtocol, @unchecked Sendable {
    private let repository: ExpenseRepositoryProtocol

    public init(repository: ExpenseRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(_ input: ExpenseSearchCriteria) async throws -> [Expense] {
        try await repository.searchExpenses(criteria: input)
    }
}
