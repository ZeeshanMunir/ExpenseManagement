import Foundation

public struct RequestBuilder: Sendable {
    private let encoder: JSONEncoder
    private let interceptorChain: InterceptorChain?

    public init(
        encoder: JSONEncoder = JSONCoding.makeEncoder(),
        interceptors: [any RequestInterceptor] = []
    ) {
        self.encoder = encoder
        self.interceptorChain = interceptors.isEmpty ? nil : InterceptorChain(interceptors: interceptors)
    }

    public func build(from endpoint: any Endpoint) async throws -> URLRequest {
        guard let url = endpoint.url() else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = endpoint.timeout ?? APIConstants.requestTimeout

        endpoint.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        try applyParameters(to: &request, endpoint: endpoint)

        if let interceptorChain {
            request = try await interceptorChain.adapt(request)
        }

        return request
    }

    private func applyParameters(to request: inout URLRequest, endpoint: any Endpoint) throws {
        switch endpoint.encoding {
        case .json:
            if let body = endpoint.body {
                request.httpBody = body
            }
        case .url:
            guard let body = endpoint.body else { return }
            guard var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false) else {
                throw APIError.invalidURL
            }
            if let query = String(data: body, encoding: .utf8) {
                components.percentEncodedQuery = query
            }
            request.url = components.url
        }
    }
}
