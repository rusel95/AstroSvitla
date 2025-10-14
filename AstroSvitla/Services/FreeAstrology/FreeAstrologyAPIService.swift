//
//  FreeAstrologyAPIService.swift
//  AstroSvitla
//
//  Created for Free Astrology API integration
//  HTTP client for Free Astrology API endpoints
//
//  ⚠️ LEGACY API - PRESERVED FOR ROLLBACK (2025-10-11)
//  This implementation has been replaced by AstrologyAPIService (api.astrology-api.io)
//  DO NOT DELETE - Keep for potential rollback
//  To restore: Remove AstrologyAPI integration and re-enable this service in NatalChartService
//

import Foundation

/// Errors specific to Free Astrology API interactions
enum FreeAstrologyError: LocalizedError {
    case authenticationFailed
    case rateLimitExceeded(retryAfter: Int)
    case invalidRequest(message: String)
    case serverError
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "Invalid or missing API key. Please check your Free Astrology API credentials in Config.swift."
        case .rateLimitExceeded(let seconds):
            return "API rate limit exceeded. Please wait \(seconds) seconds before trying again."
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        case .serverError:
            return "Free Astrology API server error. Please try again later."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Received invalid response from Free Astrology API."
        case .decodingError(let error):
            return "Failed to parse API response: \(error.localizedDescription)"
        }
    }
}

/// Protocol for Free Astrology API service (enables mocking)
protocol FreeAstrologyAPIServiceProtocol: Sendable {
    func fetchPlanets(_ request: FreeAstrologyRequest) async throws -> PlanetsResponse
    func fetchHouses(_ request: FreeAstrologyRequest) async throws -> HousesResponse
    func fetchAspects(_ request: FreeAstrologyRequest) async throws -> AspectsResponse
    func fetchNatalWheelChart(_ request: FreeAstrologyRequest) async throws -> NatalChartResponse
}

/// HTTP client for Free Astrology API
final class FreeAstrologyAPIService: FreeAstrologyAPIServiceProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let apiKey: String
    private let baseURL: String
    private let urlSession: URLSession

    // MARK: - Initialization

    init(
        apiKey: String,
        baseURL: String = Config.freeAstrologyBaseURL,
        urlSession: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.urlSession = urlSession
    }

    /// Convenience initializer using Config values
    convenience init() {
        self.init(
            apiKey: Config.freeAstrologyAPIKey,
            baseURL: Config.freeAstrologyBaseURL
        )
    }

    // MARK: - Public API Methods

    func fetchPlanets(_ request: FreeAstrologyRequest) async throws -> PlanetsResponse {
        let endpoint = "/western/planets"
        return try await performRequest(endpoint: endpoint, body: request)
    }

    func fetchHouses(_ request: FreeAstrologyRequest) async throws -> HousesResponse {
        let endpoint = "/western/houses"
        return try await performRequest(endpoint: endpoint, body: request)
    }

    func fetchAspects(_ request: FreeAstrologyRequest) async throws -> AspectsResponse {
        let endpoint = "/western/aspects"
        return try await performRequest(endpoint: endpoint, body: request)
    }

    func fetchNatalWheelChart(_ request: FreeAstrologyRequest) async throws -> NatalChartResponse {
        let endpoint = "/western/natal-wheel-chart"
        return try await performRequest(endpoint: endpoint, body: request)
    }

    // MARK: - Private HTTP Methods

    /// Perform HTTP POST request to Free Astrology API
    private func performRequest<Request: Encodable, Response: Decodable>(
        endpoint: String,
        body: Request
    ) async throws -> Response {
        // Build URL
        guard let url = URL(string: baseURL + endpoint) else {
            throw FreeAstrologyError.invalidRequest(message: "Invalid endpoint: \(endpoint)")
        }

        // Create request
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")

        // Encode body
        do {
            let encoder = JSONEncoder()
            urlRequest.httpBody = try encoder.encode(body)
        } catch {
            throw FreeAstrologyError.invalidRequest(message: "Failed to encode request body: \(error.localizedDescription)")
        }

        // Perform request
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await urlSession.data(for: urlRequest)
        } catch {
            throw FreeAstrologyError.networkError(error)
        }

        // Check HTTP status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FreeAstrologyError.invalidResponse
        }

        try validateHTTPResponse(httpResponse, data: data)

        // Decode response
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw FreeAstrologyError.decodingError(error)
        }
    }

    /// Validate HTTP response status code and handle errors
    private func validateHTTPResponse(_ response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
        case 200...299:
            // Success
            return

        case 401:
            throw FreeAstrologyError.authenticationFailed

        case 429:
            // Rate limit exceeded - extract retry-after if available
            let retryAfter = response.value(forHTTPHeaderField: "Retry-After")
                .flatMap { Int($0) } ?? 60
            throw FreeAstrologyError.rateLimitExceeded(retryAfter: retryAfter)

        case 400...499:
            // Client error - try to extract error message from response
            let message = extractErrorMessage(from: data) ?? "Client error (status \(response.statusCode))"
            throw FreeAstrologyError.invalidRequest(message: message)

        case 500...599:
            throw FreeAstrologyError.serverError

        default:
            throw FreeAstrologyError.invalidResponse
        }
    }

    /// Extract error message from API error response
    private func extractErrorMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        // Try common error message fields
        if let message = json["message"] as? String {
            return message
        }
        if let error = json["error"] as? String {
            return error
        }
        if let errorObj = json["error"] as? [String: Any],
           let message = errorObj["message"] as? String {
            return message
        }

        return nil
    }
}
