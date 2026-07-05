import Foundation

public enum NetworkDependencyFactory {
    public static func makeAPIClient(configuration: NetworkConfiguration = .default) -> APIClient {
        DefaultAPIClient(configuration: configuration)
    }

    public static func makeAuthenticatedAPIClient(
        tokenProvider: @escaping @Sendable () async throws -> String,
        configuration: NetworkConfiguration = .default
    ) -> APIClient {
        let authConfiguration = NetworkConfiguration(
            session: configuration.session,
            decoder: configuration.decoder,
            encoder: configuration.encoder,
            interceptors: [],
            authenticationProvider: BearerTokenAuthenticationProvider(tokenProvider: tokenProvider),
            retryPolicy: configuration.retryPolicy,
            logger: configuration.logger,
            reachability: configuration.reachability
        )
        return DefaultAPIClient(configuration: authConfiguration)
    }

    public static func makeReachableAPIClient(
        configuration: NetworkConfiguration = .default
    ) -> APIClient {
        let reachableConfiguration = NetworkConfiguration(
            session: configuration.session,
            decoder: configuration.decoder,
            encoder: configuration.encoder,
            interceptors: [],
            authenticationProvider: nil,
            retryPolicy: configuration.retryPolicy,
            logger: configuration.logger,
            reachability: NWPathMonitorReachability.shared
        )
        return DefaultAPIClient(configuration: reachableConfiguration)
    }
}
