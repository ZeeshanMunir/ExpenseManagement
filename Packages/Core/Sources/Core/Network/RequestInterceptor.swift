import Foundation

public protocol RequestInterceptor: Sendable {
    func adapt(_ request: URLRequest) async throws -> URLRequest
}

public struct InterceptorChain: RequestInterceptor, Sendable {
    private let interceptors: [any RequestInterceptor]

    public init(interceptors: [any RequestInterceptor]) {
        self.interceptors = interceptors
    }

    public func adapt(_ request: URLRequest) async throws -> URLRequest {
        var adaptedRequest = request
        for interceptor in interceptors {
            adaptedRequest = try await interceptor.adapt(adaptedRequest)
        }
        return adaptedRequest
    }
}

public struct HeaderRequestInterceptor: RequestInterceptor, Sendable {
    private let headers: [String: String]

    public init(headers: [String: String]) {
        self.headers = headers
    }

    public func adapt(_ request: URLRequest) async throws -> URLRequest {
        var adaptedRequest = request
        headers.forEach { key, value in
            adaptedRequest.setValue(value, forHTTPHeaderField: key)
        }
        return adaptedRequest
    }
}
