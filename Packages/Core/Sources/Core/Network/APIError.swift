import Foundation

public enum APIError: Error, LocalizedError, Equatable, Sendable {
    case invalidURL
    case noInternet
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case clientError(statusCode: Int, data: Data?)
    case serverError(statusCode: Int, data: Data?)
    case decodingFailed(message: String)
    case encodingFailed(message: String)
    case cancelled
    case timeout
    case retryLimitExceeded(attempts: Int)
    case underlying(message: String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is invalid."
        case .noInternet:
            return "No internet connection is available."
        case .invalidResponse:
            return "The server returned an invalid response."
        case .unauthorized:
            return "Authentication is required or has expired."
        case .forbidden:
            return "You do not have permission to perform this action."
        case .notFound:
            return "The requested resource was not found."
        case .clientError(let statusCode, _):
            return "Client error with status code \(statusCode)."
        case .serverError(let statusCode, _):
            return "Server error with status code \(statusCode)."
        case .decodingFailed(let message):
            return "Failed to decode response: \(message)"
        case .encodingFailed(let message):
            return "Failed to encode request body: \(message)"
        case .cancelled:
            return "The request was cancelled."
        case .timeout:
            return "The request timed out."
        case .retryLimitExceeded(let attempts):
            return "Request failed after \(attempts) attempts."
        case .underlying(let message):
            return message
        }
    }

    public static func map(_ error: Error) -> APIError {
        if let apiError = error as? APIError {
            return apiError
        }

        if let urlError = error as? URLError {
            return map(urlError)
        }

        if error is DecodingError {
            return .decodingFailed(message: error.localizedDescription)
        }

        if error is EncodingError {
            return .encodingFailed(message: error.localizedDescription)
        }

        return .underlying(message: error.localizedDescription)
    }

    public static func map(httpStatusCode: Int, data: Data?) -> APIError {
        switch httpStatusCode {
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 400..<500:
            return .clientError(statusCode: httpStatusCode, data: data)
        case 500..<600:
            return .serverError(statusCode: httpStatusCode, data: data)
        default:
            return .invalidResponse
        }
    }

    private static func map(_ error: URLError) -> APIError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            return .noInternet
        case .timedOut:
            return .timeout
        case .cancelled:
            return .cancelled
        default:
            return .underlying(message: error.localizedDescription)
        }
    }
}

public typealias NetworkError = APIError
