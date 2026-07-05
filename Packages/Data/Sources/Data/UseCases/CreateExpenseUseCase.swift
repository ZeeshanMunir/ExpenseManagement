import Domain
import Foundation

public final class CreateExpenseUseCase: CreateExpenseUseCaseProtocol, @unchecked Sendable {
    private let repository: ExpenseRepositoryProtocol

    public init(repository: ExpenseRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(_ input: CreateExpenseInput) async throws -> Expense {
        try await repository.createExpense(input)
    }
}
