import Core
import Domain
import Foundation

public protocol ExpenseSyncCoordinatorProtocol: Sendable {
    func startAutoSync() async
    func stopAutoSync() async
}

/// Observes network reachability and triggers synchronization when connectivity is restored.
public final class ExpenseSyncCoordinator: ExpenseSyncCoordinatorProtocol, @unchecked Sendable {
    private let repository: any ExpenseRepositoryProtocol
    private let reachability: any NetworkReachability
    private let configuration: ExpenseRepositoryConfiguration
    private var observationTask: Task<Void, Never>?

    public init(
        repository: any ExpenseRepositoryProtocol,
        reachability: any NetworkReachability,
        configuration: ExpenseRepositoryConfiguration = .default
    ) {
        self.repository = repository
        self.reachability = reachability
        self.configuration = configuration
    }

    public func startAutoSync() async {
        guard configuration.autoSyncOnReconnect else { return }

        observationTask?.cancel()
        observationTask = Task { [weak self] in
            guard let self else { return }
            var wasConnected = await reachability.isConnected()

            for await isConnected in reachability.connectionChanges() {
                guard !Task.isCancelled else { break }

                if isConnected && !wasConnected {
                    await self.syncOnReconnect()
                }
                wasConnected = isConnected
            }
        }
    }

    public func stopAutoSync() async {
        observationTask?.cancel()
        observationTask = nil
    }

    // MARK: - Private

    private func syncOnReconnect() async {
        do {
            _ = try await repository.retryFailedSync()
            AppLogger.data.info("Auto-sync completed after network reconnect.")
        } catch {
            AppLogger.data.debug("Auto-sync on reconnect deferred: \(error.localizedDescription)")
        }
    }
}
