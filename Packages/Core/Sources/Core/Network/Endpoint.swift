import Foundation

public protocol Endpoint: Sendable {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Data? { get }
    var encoding: ParameterEncoding { get }
    var timeout: TimeInterval? { get }
}

public extension Endpoint {
    var baseURL: String { APIConstants.baseURL }
    var headers: [String: String] {
        [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
    var queryItems: [URLQueryItem]? { nil }
    var body: Data? { nil }
    var encoding: ParameterEncoding { .json }
    var timeout: TimeInterval? { APIConstants.requestTimeout }

    func url() -> URL? {
        guard var components = URLComponents(string: baseURL + path) else {
            return nil
        }
        components.queryItems = queryItems
        return components.url
    }
}

public protocol JSONEndpoint: Endpoint {
    associatedtype Body: Encodable & Sendable
    var jsonBody: Body? { get }
}

public extension JSONEndpoint {
    var body: Data? {
        guard let jsonBody else { return nil }
        return try? JSONCoding.makeEncoder().encode(jsonBody)
    }
}

public typealias APIEndpoint = Endpoint
