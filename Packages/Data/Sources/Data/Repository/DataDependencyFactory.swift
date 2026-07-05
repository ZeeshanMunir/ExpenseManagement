import Core
import Domain
import Foundation

public enum DataDependencyFactory {
    // MARK: - Persistence

    public static func makeCoreDataManager(inMemory: Bool = false) -> CoreDataManager {
        CoreDataManager(inMemory: inMemory)
    }

    public static func makeExpenseLocalStore(
        coreDataManager: any CoreDataManaging
    ) -> ExpenseLocalStoreProtocol {
        ExpenseLocalStore(coreDataManager: coreDataManager)
    }

    public static func makeExpenseOfflineQueue(
        coreDataManager: any CoreDataManaging
    ) -> ExpenseOfflineQueueProtocol {
        ExpenseOfflineQueue(coreDataManager: coreDataManager)
    }

    // MARK: - Network

    public static func makeExpenseRemoteDataSource(
        networkClient: any APIClient
    ) -> ExpenseRemoteDataSourceProtocol {
        ExpenseRemoteDataSource(networkClient: networkClient)
    }

    // MARK: - Repository

    public static func makeExpenseRepository(
        remoteDataSource: ExpenseRemoteDataSourceProtocol,
        localStore: any ExpenseLocalStoreProtocol,
        offlineQueue: any ExpenseOfflineQueueProtocol,
        reachability: any NetworkReachability,
        configuration: ExpenseRepositoryConfiguration = .default
    ) -> ExpenseRepositoryProtocol {
        ExpenseRepository(
            remoteDataSource: remoteDataSource,
            localStore: localStore,
            offlineQueue: offlineQueue,
            reachability: reachability,
            configuration: configuration
        )
    }

    // MARK: - Use Cases

    public static func makeFetchExpensesUseCase(
        repository: ExpenseRepositoryProtocol
    ) -> FetchExpensesUseCaseProtocol {
        FetchExpensesUseCase(repository: repository)
    }

    public static func makeCreateExpenseUseCase(
        repository: ExpenseRepositoryProtocol
    ) -> CreateExpenseUseCaseProtocol {
        CreateExpenseUseCase(repository: repository)
    }

    public static func makeUpdateExpenseUseCase(
        repository: ExpenseRepositoryProtocol
    ) -> UpdateExpenseUseCaseProtocol {
        UpdateExpenseUseCase(repository: repository)
    }

    public static func makeDeleteExpenseUseCase(
        repository: ExpenseRepositoryProtocol
    ) -> DeleteExpenseUseCaseProtocol {
        DeleteExpenseUseCase(repository: repository)
    }

    public static func makeSearchExpensesUseCase(
        repository: ExpenseRepositoryProtocol
    ) -> SearchExpensesUseCaseProtocol {
        SearchExpensesUseCase(repository: repository)
    }

    public static func makeSyncExpensesUseCase(
        repository: ExpenseRepositoryProtocol
    ) -> SyncExpensesUseCaseProtocol {
        SyncExpensesUseCase(repository: repository)
    }

    public static func makeRetryFailedSyncUseCase(
        repository: ExpenseRepositoryProtocol
    ) -> RetryFailedSyncUseCaseProtocol {
        RetryFailedSyncUseCase(repository: repository)
    }

    public static func makeExpenseSyncCoordinator(
        repository: ExpenseRepositoryProtocol,
        reachability: any NetworkReachability,
        configuration: ExpenseRepositoryConfiguration = .default
    ) -> ExpenseSyncCoordinatorProtocol {
        ExpenseSyncCoordinator(
            repository: repository,
            reachability: reachability,
            configuration: configuration
        )
    }
}
