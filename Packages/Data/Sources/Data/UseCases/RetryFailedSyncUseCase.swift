import Domain
import Foundation

public struct RetryFailedSyncUseCase: RetryFailedSyncUseCaseProtocol {
    private let repository: any ExpenseRepositoryProtocol

    public init(repository: any ExpenseRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> SyncExpensesResult {
        try await repository.retryFailedSync()
    }
}
