import Foundation
import Network

public protocol NetworkReachability: Sendable {
    func isConnected() async -> Bool
    func requireConnection() async throws
    func connectionChanges() -> AsyncStream<Bool>
}

public actor NWPathMonitorReachability: NetworkReachability {
    public static let shared = NWPathMonitorReachability()

    private let monitor = NWPathMonitor()
    private var connected = true
    private var continuations: [UUID: AsyncStream<Bool>.Continuation] = [:]

    public init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            Task { await self.updateConnectionStatus(path.status == .satisfied) }
        }
        monitor.start(queue: DispatchQueue(label: "com.smartexpensemanager.network.reachability"))
    }

    public func isConnected() async -> Bool {
        connected
    }

    public func requireConnection() async throws {
        guard connected else {
            throw APIError.noInternet
        }
    }

    nonisolated public func connectionChanges() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let id = UUID()
            Task {
                let current = await self.isConnected()
                continuation.yield(current)
                await self.registerContinuation(id: id, continuation: continuation)
            }
            continuation.onTermination = { @Sendable _ in
                Task { await self.removeContinuation(id: id) }
            }
        }
    }

    private func registerContinuation(id: UUID, continuation: AsyncStream<Bool>.Continuation) {
        continuations[id] = continuation
    }

    private func removeContinuation(id: UUID) {
        continuations.removeValue(forKey: id)
    }

    private func updateConnectionStatus(_ isConnected: Bool) {
        guard connected != isConnected else { return }
        connected = isConnected
        for continuation in continuations.values {
            continuation.yield(isConnected)
        }
    }
}

public struct AlwaysConnectedReachability: NetworkReachability, Sendable {
    public init() {}

    public func isConnected() async -> Bool { true }

    public func requireConnection() async throws {}

    public func connectionChanges() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            continuation.yield(true)
            continuation.finish()
        }
    }
}
