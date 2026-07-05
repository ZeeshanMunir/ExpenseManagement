import Foundation

public protocol APIClient: Sendable {
    func request<T: Decodable>(
        _ endpoint: any Endpoint,
        responseType: T.Type
    ) async throws -> T

    func request(_ endpoint: any Endpoint) async throws
}

public extension APIClient {
    func request(_ endpoint: any Endpoint) async throws {
        _ = try await request(endpoint, responseType: EmptyResponse.self)
    }
}

public typealias NetworkClientProtocol = APIClient
