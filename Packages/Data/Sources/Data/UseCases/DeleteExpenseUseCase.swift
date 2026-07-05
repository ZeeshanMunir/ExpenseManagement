import Domain
import Foundation

public final class DeleteExpenseUseCase: DeleteExpenseUseCaseProtocol, @unchecked Sendable {
    private let repository: ExpenseRepositoryProtocol

    public init(repository: ExpenseRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(_ input: UUID) async throws {
        try await repository.deleteExpense(id: input)
    }
}
