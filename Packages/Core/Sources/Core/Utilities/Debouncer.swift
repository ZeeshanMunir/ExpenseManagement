import Foundation

/// Cancels in-flight delayed work when new events arrive. Used for search and similar UI debouncing.
public actor Debouncer {
    private var task: Task<Void, Never>?
    private let nanoseconds: UInt64

    public init(nanoseconds: UInt64) {
        self.nanoseconds = nanoseconds
    }

    public func schedule(_ action: @escaping @Sendable () async -> Void) {
        task?.cancel()
        task = Task {
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else { return }
            await action()
        }
    }

    public func cancel() {
        task?.cancel()
        task = nil
    }
}
