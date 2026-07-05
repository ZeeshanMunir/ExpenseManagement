import Foundation

public protocol RetryPolicy: Sendable {
    func shouldRetry(for error: APIError, attempt: Int) -> Bool
    func delay(for attempt: Int) -> TimeInterval
}

public struct ExponentialBackoffRetryPolicy: RetryPolicy, Sendable {
    public let maxAttempts: Int
    public let baseDelay: TimeInterval
    public let multiplier: Double
    public let retryableStatusCodes: Set<Int>

    public init(
        maxAttempts: Int = 3,
        baseDelay: TimeInterval = 1.0,
        multiplier: Double = 2.0,
        retryableStatusCodes: Set<Int> = [408, 429, 500, 502, 503, 504]
    ) {
        self.maxAttempts = maxAttempts
        self.baseDelay = baseDelay
        self.multiplier = multiplier
        self.retryableStatusCodes = retryableStatusCodes
    }

    public func shouldRetry(for error: APIError, attempt: Int) -> Bool {
        guard attempt < maxAttempts else { return false }

        switch error {
        case .noInternet, .timeout:
            return true
        case .serverError(let statusCode, _), .clientError(let statusCode, _):
            return retryableStatusCodes.contains(statusCode)
        default:
            return false
        }
    }

    public func delay(for attempt: Int) -> TimeInterval {
        baseDelay * pow(multiplier, Double(max(attempt - 1, 0)))
    }
}

public struct NoRetryPolicy: RetryPolicy, Sendable {
    public init() {}

    public func shouldRetry(for error: APIError, attempt: Int) -> Bool {
        false
    }

    public func delay(for attempt: Int) -> TimeInterval {
        0
    }
}
