//
//  ProkralaAPIService.swift
//  AstroSvitla
//
//  HTTP client for Prokerala Astrology API
//

import Foundation

// MARK: - Protocol for Dependency Injection

protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

protocol ProkralaAPIServiceProtocol {
    func fetchChartData(_ request: NatalChartRequest) async throws -> ProkralaChartDataResponse
    func generateChartImage(_ request: NatalChartRequest) async throws -> ProkralaChartImageResponse
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case authenticationFailed
    case rateLimitExceeded(retryAfter: TimeInterval)
    case serverError(statusCode: Int)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Received invalid response from server"
        case .httpError(let code):
            return "Server returned error code: \(code)"
        case .authenticationFailed:
            return "API authentication failed. Please check your credentials."
        case .rateLimitExceeded(let seconds):
            return "Request limit reached. Please wait \(Int(seconds)) seconds."
        case .serverError(let code):
            return "Server error (code \(code)). Please try again later."
        case .networkError:
            return "Unable to connect. Please check your internet connection."
        }
    }
}

// MARK: - API Service Implementation

final class ProkralaAPIService: ProkralaAPIServiceProtocol {

    private let userID: String
    private let apiKey: String
    private let baseURL: String
    private let session: URLSessionProtocol

    init(
        userID: String,
        apiKey: String,
        baseURL: String = "https://json.astrologyapi.com/v1",
        session: URLSessionProtocol = URLSession.shared
    ) {
        self.userID = userID
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - Public Methods

    func fetchChartData(_ request: NatalChartRequest) async throws -> ProkralaChartDataResponse {
        let url = URL(string: "\(baseURL)/western_chart_data")!
        let urlRequest = try buildRequest(url: url, body: request.toChartDataBody())

        return try await fetchWithRetry(maxAttempts: 3) {
            let (data, response) = try await self.session.data(for: urlRequest)
            try self.validateResponse(response)
            return try JSONDecoder().decode(ProkralaChartDataResponse.self, from: data)
        }
    }

    func generateChartImage(_ request: NatalChartRequest) async throws -> ProkralaChartImageResponse {
        let url = URL(string: "\(baseURL)/natal_wheel_chart")!
        let urlRequest = try buildRequest(url: url, body: request.toChartImageBody())

        return try await fetchWithRetry(maxAttempts: 3) {
            let (data, response) = try await self.session.data(for: urlRequest)
            try self.validateResponse(response)
            return try JSONDecoder().decode(ProkralaChartImageResponse.self, from: data)
        }
    }

    // MARK: - Private Helpers

    private func buildRequest(url: URL, body: [String: Any]) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Basic Authentication
        let credentials = "\(userID):\(apiKey)"
        let base64Credentials = Data(credentials.utf8).base64EncodedString()
        request.addValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")

        // Headers
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("en", forHTTPHeaderField: "Accept-Language")

        // Timeouts
        request.timeoutInterval = 30.0

        // Body
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        return request
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.authenticationFailed
        case 429:
            let retryAfter = TimeInterval(httpResponse.value(forHTTPHeaderField: "Retry-After") ?? "60") ?? 60
            throw APIError.rateLimitExceeded(retryAfter: retryAfter)
        case 500...599:
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        default:
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
    }

    private func fetchWithRetry<T>(
        maxAttempts: Int = 3,
        operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error?

        for attempt in 0..<maxAttempts {
            do {
                return try await operation()
            } catch let error as APIError {
                // Don't retry client errors (4xx) except rate limit
                switch error {
                case .rateLimitExceeded, .serverError, .networkError:
                    lastError = error
                    if attempt < maxAttempts - 1 {
                        let delay = pow(2.0, Double(attempt)) // 1s, 2s, 4s
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    }
                default:
                    throw error // Don't retry auth failures or invalid responses
                }
            } catch {
                lastError = APIError.networkError(error)
                if attempt < maxAttempts - 1 {
                    let delay = pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        throw lastError ?? APIError.invalidResponse
    }
}
