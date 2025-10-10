//
//  ProkralaAPIService.swift
//  AstroSvitla
//
//  HTTP client for Prokerala Astrology API (api.prokerala.com)
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

enum AstroAPIError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case authenticationFailed(String)
    case rateLimitExceeded(retryAfter: TimeInterval)
    case serverError(statusCode: Int)
    case networkError(Error)
    case invalidToken(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Received invalid response from server"
        case .httpError(let code):
            return "Server returned error code: \(code)"
        case .authenticationFailed(let detail):
            return "API authentication failed: \(detail)"
        case .rateLimitExceeded(let seconds):
            return "Request limit reached. Please wait \(Int(seconds)) seconds."
        case .serverError(let code):
            return "Server error (code \(code)). Please try again later."
        case .networkError:
            return "Unable to connect. Please check your internet connection."
        case .invalidToken(let detail):
            return "Invalid API token: \(detail)"
        }
    }
}

// MARK: - API Service Implementation

final class ProkralaAPIService: ProkralaAPIServiceProtocol {

    private let token: String
    private let baseURL: String
    private let session: URLSessionProtocol

    init(
        token: String,
        baseURL: String = Config.prokeralaAPIBaseURL,
        session: URLSessionProtocol = URLSession.shared
    ) {
        self.token = token
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - Public Methods

    func fetchChartData(_ request: NatalChartRequest) async throws -> ProkralaChartDataResponse {
        // Prokerala uses GET requests with query parameters
        var components = URLComponents(string: "\(baseURL)/astrology/natal-chart")!
        components.queryItems = request.toQueryParameters()

        guard let url = components.url else {
            throw AstroAPIError.invalidResponse
        }

        let urlRequest = try buildRequest(url: url)

        return try await fetchWithRetry(maxAttempts: 3) {
            let (data, response) = try await self.session.data(for: urlRequest)
            try self.validateResponse(response, data: data)

            // Decode response
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(ProkralaChartDataResponse.self, from: data)
        }
    }

    func generateChartImage(_ request: NatalChartRequest) async throws -> ProkralaChartImageResponse {
        // For now, return empty response as Prokerala API doesn't have separate image endpoint
        // Chart images are generated client-side or through different service
        return ProkralaChartImageResponse(
            status: false,
            chart_url: "",
            msg: "Chart visualization not available from Prokerala API"
        )
    }

    // MARK: - Private Helpers

    private func buildRequest(url: URL) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Bearer Token Authentication
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Headers
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("en", forHTTPHeaderField: "Accept-Language")

        // Timeouts
        request.timeoutInterval = 30.0

        return request
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AstroAPIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401, 403:
            // Try to parse error details
            if let errorResponse = try? JSONDecoder().decode(ProkralaErrorResponse.self, from: data),
               let error = errorResponse.errors.first {
                throw AstroAPIError.authenticationFailed(error.detail)
            }
            throw AstroAPIError.authenticationFailed("Authentication failed")
        case 429:
            let retryAfter = TimeInterval(httpResponse.value(forHTTPHeaderField: "Retry-After") ?? "60") ?? 60
            throw AstroAPIError.rateLimitExceeded(retryAfter: retryAfter)
        case 500...599:
            throw AstroAPIError.serverError(statusCode: httpResponse.statusCode)
        default:
            throw AstroAPIError.httpError(statusCode: httpResponse.statusCode)
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
            } catch let error as AstroAPIError {
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
                lastError = AstroAPIError.networkError(error)
                if attempt < maxAttempts - 1 {
                    let delay = pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        throw lastError ?? AstroAPIError.invalidResponse
    }
}

// MARK: - Error Response Model

struct ProkralaErrorResponse: Codable {
    let id: String
    let status: String
    let errors: [ProkralaError]
}

struct ProkralaError: Codable {
    let title: String
    let detail: String
    let code: String
}
