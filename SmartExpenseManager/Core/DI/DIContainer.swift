import Core
import Data
import Domain
import Foundation

/// Contract for the application's dependency graph.
public protocol DIContainer: AnyObject, Sendable {
    // MARK: - Network
    var apiClient: any APIClient { get }
    var reachability: any NetworkReachability { get }

    // MARK: - Persistence
    var coreDataManager: any CoreDataManaging { get }
    var localStore: any ExpenseLocalStoreProtocol { get }
    var offlineQueue: any ExpenseOfflineQueueProtocol { get }

    // MARK: - Services
    var remoteDataSource: any ExpenseRemoteDataSourceProtocol { get }

    // MARK: - Repositories
    var expenseRepository: any ExpenseRepositoryProtocol { get }

    // MARK: - Use Cases
    var fetchExpensesUseCase: any FetchExpensesUseCaseProtocol { get }
    var createExpenseUseCase: any CreateExpenseUseCaseProtocol { get }
    var updateExpenseUseCase: any UpdateExpenseUseCaseProtocol { get }
    var deleteExpenseUseCase: any DeleteExpenseUseCaseProtocol { get }
    var searchExpensesUseCase: any SearchExpensesUseCaseProtocol { get }
    var syncExpensesUseCase: any SyncExpensesUseCaseProtocol { get }
    var retryFailedSyncUseCase: any RetryFailedSyncUseCaseProtocol { get }
    var syncCoordinator: any ExpenseSyncCoordinatorProtocol { get }
}
