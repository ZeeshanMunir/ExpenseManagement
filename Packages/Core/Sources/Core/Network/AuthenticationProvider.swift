import Foundation

public protocol AuthenticationProvider: Sendable {
    func apply(to request: URLRequest) async throws -> URLRequest
}

public struct BearerTokenAuthenticationProvider: AuthenticationProvider, Sendable {
    public static let authorizationHeader = "Authorization"
    public static let bearerPrefix = "Bearer"

    private let tokenProvider: @Sendable () async throws -> String

    public init(tokenProvider: @escaping @Sendable () async throws -> String) {
        self.tokenProvider = tokenProvider
    }

    public init(staticToken: String) {
        self.tokenProvider = { staticToken }
    }

    public func apply(to request: URLRequest) async throws -> URLRequest {
        var authenticatedRequest = request
        let token = try await tokenProvider()
        authenticatedRequest.setValue(
            "\(Self.bearerPrefix) \(token)",
            forHTTPHeaderField: Self.authorizationHeader
        )
        return authenticatedRequest
    }
}

public struct AuthenticationInterceptor: RequestInterceptor, Sendable {
    private let authenticationProvider: any AuthenticationProvider

    public init(authenticationProvider: any AuthenticationProvider) {
        self.authenticationProvider = authenticationProvider
    }

    public func adapt(_ request: URLRequest) async throws -> URLRequest {
        try await authenticationProvider.apply(to: request)
    }
}

public struct APIKeyAuthenticationProvider: AuthenticationProvider, Sendable {
    private let headerName: String
    private let keyProvider: @Sendable () async throws -> String

    public init(headerName: String = "X-API-Key", keyProvider: @escaping @Sendable () async throws -> String) {
        self.headerName = headerName
        self.keyProvider = keyProvider
    }

    public func apply(to request: URLRequest) async throws -> URLRequest {
        var authenticatedRequest = request
        let apiKey = try await keyProvider()
        authenticatedRequest.setValue(apiKey, forHTTPHeaderField: headerName)
        return authenticatedRequest
    }
}
