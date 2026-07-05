import Core
import Data
import Domain
import Foundation

/// Production composition root. Owns the full dependency graph for a single app session.
public final class AppContainer: DIContainer, @unchecked Sendable {
    // MARK: - Configuration

    public struct Configuration: Sendable {
        public var apiClient: (any APIClient)?
        public var reachability: (any NetworkReachability)?
        public var coreDataManager: (any CoreDataManaging)?
        public var localStore: (any ExpenseLocalStoreProtocol)?
        public var offlineQueue: (any ExpenseOfflineQueueProtocol)?
        public var remoteDataSource: (any ExpenseRemoteDataSourceProtocol)?
        public var expenseRepository: (any ExpenseRepositoryProtocol)?
        public var syncCoordinator: (any ExpenseSyncCoordinatorProtocol)?
        public var repositoryConfiguration: ExpenseRepositoryConfiguration

        public init(
            apiClient: (any APIClient)? = nil,
            reachability: (any NetworkReachability)? = nil,
            coreDataManager: (any CoreDataManaging)? = nil,
            localStore: (any ExpenseLocalStoreProtocol)? = nil,
            offlineQueue: (any ExpenseOfflineQueueProtocol)? = nil,
            remoteDataSource: (any ExpenseRemoteDataSourceProtocol)? = nil,
            expenseRepository: (any ExpenseRepositoryProtocol)? = nil,
            syncCoordinator: (any ExpenseSyncCoordinatorProtocol)? = nil,
            repositoryConfiguration: ExpenseRepositoryConfiguration = .default
        ) {
            self.apiClient = apiClient
            self.reachability = reachability
            self.coreDataManager = coreDataManager
            self.localStore = localStore
            self.offlineQueue = offlineQueue
            self.remoteDataSource = remoteDataSource
            self.expenseRepository = expenseRepository
            self.syncCoordinator = syncCoordinator
            self.repositoryConfiguration = repositoryConfiguration
        }

        public static let production = Configuration()

        public static func testing(
            apiClient: any APIClient = MockAPIClient(),
            coreDataManager: any CoreDataManaging = MockCoreDataManager(),
            reachability: any NetworkReachability = AlwaysConnectedReachability(),
            repositoryConfiguration: ExpenseRepositoryConfiguration = ExpenseRepositoryConfiguration(
                attemptImmediateSyncWhenOnline: false,
                autoSyncOnReconnect: false
            )
        ) -> Configuration {
            Configuration(
                apiClient: apiClient,
                reachability: reachability,
                coreDataManager: coreDataManager,
                repositoryConfiguration: repositoryConfiguration
            )
        }
    }

    // MARK: - Network

    public let apiClient: any APIClient
    public let reachability: any NetworkReachability

    // MARK: - Persistence

    public let coreDataManager: any CoreDataManaging
    public let localStore: any ExpenseLocalStoreProtocol
    public let offlineQueue: any ExpenseOfflineQueueProtocol

    // MARK: - Services

    public let remoteDataSource: any ExpenseRemoteDataSourceProtocol

    // MARK: - Repositories

    public let expenseRepository: any ExpenseRepositoryProtocol

    // MARK: - Sync

    public let syncCoordinator: any ExpenseSyncCoordinatorProtocol

    // MARK: - Use Cases

    public let fetchExpensesUseCase: any FetchExpensesUseCaseProtocol
    public let createExpenseUseCase: any CreateExpenseUseCaseProtocol
    public let updateExpenseUseCase: any UpdateExpenseUseCaseProtocol
    public let deleteExpenseUseCase: any DeleteExpenseUseCaseProtocol
    public let searchExpensesUseCase: any SearchExpensesUseCaseProtocol
    public let syncExpensesUseCase: any SyncExpensesUseCaseProtocol
    public let retryFailedSyncUseCase: any RetryFailedSyncUseCaseProtocol

    // MARK: - Init

    public init(configuration: Configuration = .production) {
        let coreDataManager = configuration.coreDataManager ?? CoreDataManager.shared
        let reachability = configuration.reachability ?? NWPathMonitorReachability.shared
        let apiClient = configuration.apiClient ?? NetworkDependencyFactory.makeReachableAPIClient()
        let localStore = configuration.localStore ?? DataDependencyFactory.makeExpenseLocalStore(
            coreDataManager: coreDataManager
        )
        let offlineQueue = configuration.offlineQueue ?? DataDependencyFactory.makeExpenseOfflineQueue(
            coreDataManager: coreDataManager
        )
        let remoteDataSource = configuration.remoteDataSource ?? DataDependencyFactory.makeExpenseRemoteDataSource(
            networkClient: apiClient
        )
        let expenseRepository = configuration.expenseRepository ?? DataDependencyFactory.makeExpenseRepository(
            remoteDataSource: remoteDataSource,
            localStore: localStore,
            offlineQueue: offlineQueue,
            reachability: reachability,
            configuration: configuration.repositoryConfiguration
        )
        let syncCoordinator = configuration.syncCoordinator ?? DataDependencyFactory.makeExpenseSyncCoordinator(
            repository: expenseRepository,
            reachability: reachability,
            configuration: configuration.repositoryConfiguration
        )

        self.coreDataManager = coreDataManager
        self.apiClient = apiClient
        self.reachability = reachability
        self.localStore = localStore
        self.offlineQueue = offlineQueue
        self.remoteDataSource = remoteDataSource
        self.expenseRepository = expenseRepository
        self.syncCoordinator = syncCoordinator

        self.fetchExpensesUseCase = DataDependencyFactory.makeFetchExpensesUseCase(
            repository: expenseRepository
        )
        self.createExpenseUseCase = DataDependencyFactory.makeCreateExpenseUseCase(
            repository: expenseRepository
        )
        self.updateExpenseUseCase = DataDependencyFactory.makeUpdateExpenseUseCase(
            repository: expenseRepository
        )
        self.deleteExpenseUseCase = DataDependencyFactory.makeDeleteExpenseUseCase(
            repository: expenseRepository
        )
        self.searchExpensesUseCase = DataDependencyFactory.makeSearchExpensesUseCase(
            repository: expenseRepository
        )
        self.syncExpensesUseCase = DataDependencyFactory.makeSyncExpensesUseCase(
            repository: expenseRepository
        )
        self.retryFailedSyncUseCase = DataDependencyFactory.makeRetryFailedSyncUseCase(
            repository: expenseRepository
        )
    }
}
