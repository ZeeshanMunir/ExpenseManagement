import Core
import Data
import Domain
import Foundation

enum RepositoryTestDoubles {
  struct MockExpenseRemoteDataSource: ExpenseRemoteDataSourceProtocol {
    func fetchExpenses() async throws -> [ExpenseDTO] { [] }
    func createExpense(_ expense: ExpenseDTO) async throws {}
    func updateExpense(_ expense: ExpenseDTO) async throws {}
    func deleteExpense(id: UUID) async throws {}
  }

  struct FailingExpenseRemoteDataSource: ExpenseRemoteDataSourceProtocol {
    func fetchExpenses() async throws -> [ExpenseDTO] { throw APIError.noInternet }
    func createExpense(_ expense: ExpenseDTO) async throws { throw APIError.noInternet }
    func updateExpense(_ expense: ExpenseDTO) async throws { throw APIError.noInternet }
    func deleteExpense(id: UUID) async throws { throw APIError.noInternet }
  }

  struct OfflineReachability: NetworkReachability {
    func isConnected() async -> Bool { false }
    func requireConnection() async throws { throw APIError.noInternet }
    func connectionChanges() -> AsyncStream<Bool> {
      AsyncStream { continuation in
        continuation.yield(false)
        continuation.finish()
      }
    }
  }

  final class ConditionalExpenseRemoteDataSource: ExpenseRemoteDataSourceProtocol, @unchecked Sendable {
    var shouldSucceed = false

    func fetchExpenses() async throws -> [ExpenseDTO] { [] }

    func createExpense(_ expense: ExpenseDTO) async throws {
      guard shouldSucceed else { throw APIError.noInternet }
    }

    func updateExpense(_ expense: ExpenseDTO) async throws { throw APIError.noInternet }
    func deleteExpense(id: UUID) async throws { throw APIError.noInternet }
  }

  final class ReconnectingReachability: NetworkReachability, @unchecked Sendable {
    private let continuation: AsyncStream<Bool>.Continuation
    private let stream: AsyncStream<Bool>
    private var connected: Bool

    init(initiallyConnected: Bool) {
      connected = initiallyConnected
      var capturedContinuation: AsyncStream<Bool>.Continuation!
      stream = AsyncStream { continuation in
        capturedContinuation = continuation
        continuation.yield(initiallyConnected)
      }
      continuation = capturedContinuation
    }

    func isConnected() async -> Bool { connected }

    func requireConnection() async throws {
      guard connected else { throw APIError.noInternet }
    }

    func connectionChanges() -> AsyncStream<Bool> { stream }

    func reconnect() {
      connected = true
      continuation.yield(true)
    }
  }

  static func makeRepository(
    remote: ExpenseRemoteDataSourceProtocol,
    reachability: NetworkReachability,
    attemptImmediateSync: Bool = false,
    maxSyncRetries: Int = 3
  ) -> (ExpenseRepository, ExpenseLocalStore, ExpenseOfflineQueue, MockCoreDataManager) {
    let manager = MockCoreDataManager()
    let localStore = ExpenseLocalStore(coreDataManager: manager)
    let offlineQueue = ExpenseOfflineQueue(coreDataManager: manager)
    let repository = ExpenseRepository(
      remoteDataSource: remote,
      localStore: localStore,
      offlineQueue: offlineQueue,
      reachability: reachability,
      configuration: ExpenseRepositoryConfiguration(
        maxSyncRetries: maxSyncRetries,
        attemptImmediateSyncWhenOnline: attemptImmediateSync
      )
    )
    return (repository, localStore, offlineQueue, manager)
  }
}
