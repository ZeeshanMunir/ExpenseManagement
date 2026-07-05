import Foundation

public final class MockAPIClient: APIClient, @unchecked Sendable {
    public var requestHandler: (@Sendable (any Endpoint) async throws -> (Data, HTTPURLResponse))?
    public var decodedHandler: (@Sendable (any Endpoint) async throws -> Any)?

    public private(set) var requestedEndpoints: [any Endpoint] = []
    public var shouldFail = false
    public var errorToThrow: APIError = .serverError(statusCode: 500, data: nil)

    public init() {}

    public func request<T: Decodable>(
        _ endpoint: any Endpoint,
        responseType: T.Type
    ) async throws -> T {
        requestedEndpoints.append(endpoint)

        if shouldFail {
            throw errorToThrow
        }

        if let decodedHandler {
            guard let value = try await decodedHandler(endpoint) as? T else {
                throw APIError.decodingFailed(message: "Mock returned unexpected type.")
            }
            return value
        }

        if let requestHandler {
            let (data, _) = try await requestHandler(endpoint)
            return try JSONCoding.makeDecoder().decode(T.self, from: data)
        }

        if responseType == EmptyResponse.self {
            return EmptyResponse() as! T
        }

        throw APIError.underlying(message: "MockAPIClient has no handler configured.")
    }
}
