import Foundation

public protocol NetworkLogging: Sendable {
    func logRequest(_ request: URLRequest)
    func logResponse(_ response: HTTPURLResponse?, data: Data?, error: Error?, duration: TimeInterval)
}

public struct DefaultNetworkLogger: NetworkLogging, Sendable {
    private let isEnabled: Bool
    private let redactedHeaders: Set<String>

    public init(
        isEnabled: Bool = true,
        redactedHeaders: Set<String> = ["Authorization", "X-API-Key"]
    ) {
        self.isEnabled = isEnabled
        self.redactedHeaders = redactedHeaders
    }

    public func logRequest(_ request: URLRequest) {
        guard isEnabled else { return }

        var message = """
        ➡️ [REQUEST] \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "unknown")
        """

        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            message += "\nHeaders: \(sanitize(headers))"
        }

        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            message += "\nBody: \(bodyString)"
        }

        AppLogger.network.debug("\(message, privacy: .public)")
    }

    public func logResponse(
        _ response: HTTPURLResponse?,
        data: Data?,
        error: Error?,
        duration: TimeInterval
    ) {
        guard isEnabled else { return }

        let statusCode = response?.statusCode ?? 0
        let icon = (200...299).contains(statusCode) ? "✅" : "❌"

        var message = """
        \(icon) [RESPONSE] \(statusCode) (\(String(format: "%.2f", duration))s)
        """

        if let url = response?.url?.absoluteString {
            message += "\nURL: \(url)"
        }

        if let error {
            message += "\nError: \(error.localizedDescription)"
        }

        if let data,
           let bodyString = String(data: data, encoding: .utf8),
           !bodyString.isEmpty {
            message += "\nBody: \(bodyString)"
        }

        AppLogger.network.debug("\(message, privacy: .public)")
    }

    private func sanitize(_ headers: [String: String]) -> [String: String] {
        headers.reduce(into: [String: String]()) { result, pair in
            if redactedHeaders.contains(pair.key) {
                result[pair.key] = "***"
            } else {
                result[pair.key] = pair.value
            }
        }
    }
}

public struct SilentNetworkLogger: NetworkLogging, Sendable {
    public init() {}

    public func logRequest(_ request: URLRequest) {}
    public func logResponse(_ response: HTTPURLResponse?, data: Data?, error: Error?, duration: TimeInterval) {}
}
