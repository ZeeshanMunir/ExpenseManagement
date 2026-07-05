import Domain
import Foundation

public final class UpdateExpenseUseCase: UpdateExpenseUseCaseProtocol, @unchecked Sendable {
    private let repository: ExpenseRepositoryProtocol

    public init(repository: ExpenseRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(_ input: UpdateExpenseInput) async throws -> Expense {
        try await repository.updateExpense(input)
    }
}
