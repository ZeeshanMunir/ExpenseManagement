import Core
import Foundation
import Testing

struct APIClientTests {
    @Test func mockClientReturnsConfiguredResponse() async throws {
        let mockClient = MockAPIClient()
        let expected = ExpenseTestResponse(expenses: [])

        mockClient.decodedHandler = { _ in expected }

        let result = try await mockClient.request(
            TestEndpoint.fetch,
            responseType: ExpenseTestResponse.self
        )

        #expect(result.expenses.isEmpty)
        #expect(mockClient.requestedEndpoints.count == 1)
    }

    @Test func mockClientThrowsConfiguredError() async {
        let mockClient = MockAPIClient()
        mockClient.shouldFail = true
        mockClient.errorToThrow = .unauthorized

        await #expect(throws: APIError.unauthorized) {
            _ = try await mockClient.request(
                TestEndpoint.fetch,
                responseType: ExpenseTestResponse.self
            )
        }
    }

    @Test func apiErrorMapsUnauthorizedStatusCode() {
        let error = APIError.map(httpStatusCode: 401, data: nil)
        #expect(error == .unauthorized)
    }

    @Test func apiErrorMapsNoInternetFromURLError() {
        let urlError = URLError(.notConnectedToInternet)
        let error = APIError.map(urlError)
        #expect(error == .noInternet)
    }

    @Test func retryPolicyRetriesServerErrors() {
        let policy = ExponentialBackoffRetryPolicy(maxAttempts: 3)
        let error = APIError.serverError(statusCode: 503, data: nil)

        #expect(policy.shouldRetry(for: error, attempt: 1))
        #expect(policy.shouldRetry(for: error, attempt: 2))
        #expect(!policy.shouldRetry(for: error, attempt: 3))
    }

    @Test func bearerTokenInterceptorAddsAuthorizationHeader() async throws {
        let provider = BearerTokenAuthenticationProvider(staticToken: "test-token")
        var request = URLRequest(url: URL(string: "https://example.com")!)
        request = try await provider.apply(to: request)

        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")
    }

    @Test func requestBuilderBuildsValidRequest() async throws {
        let builder = RequestBuilder()
        let request = try await builder.build(from: TestEndpoint.fetch)

        #expect(request.httpMethod == "GET")
        #expect(request.url?.absoluteString.contains("/expenses") == true)
    }
}

private enum TestEndpoint: Endpoint {
    case fetch

    var path: String { "/expenses" }
    var method: HTTPMethod { .get }
    var baseURL: String { "https://example.com" }
}

private struct ExpenseTestResponse: Decodable, Sendable {
    let expenses: [String]
}
