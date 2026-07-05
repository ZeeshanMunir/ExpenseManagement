import Foundation

public struct NetworkConfiguration: Sendable {
    public let session: URLSession
    public let decoder: JSONDecoder
    public let encoder: JSONEncoder
    public let requestBuilder: RequestBuilder
    public let retryPolicy: any RetryPolicy
    public let logger: any NetworkLogging
    public let reachability: any NetworkReachability

    public init(
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONCoding.makeDecoder(),
        encoder: JSONEncoder = JSONCoding.makeEncoder(),
        interceptors: [any RequestInterceptor] = [],
        authenticationProvider: (any AuthenticationProvider)? = nil,
        retryPolicy: any RetryPolicy = ExponentialBackoffRetryPolicy(),
        logger: any NetworkLogging = DefaultNetworkLogger(),
        reachability: any NetworkReachability = AlwaysConnectedReachability()
    ) {
        var allInterceptors = interceptors
        if let authenticationProvider {
            allInterceptors.append(AuthenticationInterceptor(authenticationProvider: authenticationProvider))
        }

        self.session = session
        self.decoder = decoder
        self.encoder = encoder
        self.requestBuilder = RequestBuilder(encoder: encoder, interceptors: allInterceptors)
        self.retryPolicy = retryPolicy
        self.logger = logger
        self.reachability = reachability
    }

    public static let `default` = NetworkConfiguration()
}
