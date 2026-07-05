import Foundation

public final class DefaultAPIClient: APIClient, @unchecked Sendable {
    private let configuration: NetworkConfiguration

    public init(configuration: NetworkConfiguration = .default) {
        self.configuration = configuration
    }

    public func request<T: Decodable>(
        _ endpoint: any Endpoint,
        responseType: T.Type
    ) async throws -> T {
        try await configuration.reachability.requireConnection()

        var attempt = 0

        while true {
            attempt += 1

            do {
                return try await performRequest(endpoint, responseType: responseType)
            } catch {
                let mappedError = APIError.map(error)

                guard configuration.retryPolicy.shouldRetry(for: mappedError, attempt: attempt) else {
                    throw mappedError
                }

                let delay = configuration.retryPolicy.delay(for: attempt)
                if delay > 0 {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
    }

    private func performRequest<T: Decodable>(
        _ endpoint: any Endpoint,
        responseType: T.Type
    ) async throws -> T {
        let request = try await configuration.requestBuilder.build(from: endpoint)
        let startTime = Date()

        configuration.logger.logRequest(request)

        do {
            let (data, response) = try await configuration.session.data(for: request)
            let duration = Date().timeIntervalSince(startTime)

            guard let httpResponse = response as? HTTPURLResponse else {
                configuration.logger.logResponse(nil, data: data, error: APIError.invalidResponse, duration: duration)
                throw APIError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let apiError = APIError.map(httpStatusCode: httpResponse.statusCode, data: data)
                configuration.logger.logResponse(httpResponse, data: data, error: apiError, duration: duration)
                throw apiError
            }

            configuration.logger.logResponse(httpResponse, data: data, error: nil, duration: duration)

            if responseType == EmptyResponse.self {
                return EmptyResponse() as! T
            }

            do {
                return try configuration.decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingFailed(message: error.localizedDescription)
            }
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            let mappedError = APIError.map(error)
            configuration.logger.logResponse(nil, data: nil, error: mappedError, duration: duration)
            throw mappedError
        }
    }
}

public typealias URLSessionNetworkClient = DefaultAPIClient
