//
//  ProkralaAPIService.swift
//  AstroSvitla
//
//  HTTP client for Prokerala Astrology API (api.prokerala.com)
//

import Foundation

// MARK: - Protocol for Dependency Injection

protocol URLSessionProtocol: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}
extension URLSession: @unchecked Sendable {}

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

    private let baseURL: String
    private let session: URLSessionProtocol
    private let tokenManager: ProkeralaTokenManager

    init(
        clientID: String,
        clientSecret: String,
        baseURL: String = Config.prokeralaAPIBaseURL,
        session: URLSessionProtocol = URLSession.shared
    ) {
        self.baseURL = baseURL
        self.session = session
        self.tokenManager = ProkeralaTokenManager(
            clientID: clientID,
            clientSecret: clientSecret,
            session: session
        )
    }

    // MARK: - Public Methods

    func fetchChartData(_ request: NatalChartRequest) async throws -> ProkralaChartDataResponse {
        // Prokerala uses GET requests with query parameters
        let parameters = request.toQueryParameters()
        var components = URLComponents(string: "\(baseURL)/astrology/natal-chart")!
        components.percentEncodedQuery = percentEncodedQuery(from: parameters)

        guard let url = components.url else {
            throw AstroAPIError.invalidResponse
        }

        return try await fetchWithRetry(maxAttempts: 3) {
            let accessToken = try await self.tokenManager.accessToken()
            let urlRequest = self.buildRequest(url: url, accessToken: accessToken)

            do {
                let (data, response) = try await self.session.data(for: urlRequest)
                try self.validateResponse(response, data: data)

                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                return try decoder.decode(ProkralaChartDataResponse.self, from: data)
            } catch let error as AstroAPIError {
                if case .authenticationFailed = error {
                    await self.tokenManager.invalidate()
                }
                throw error
            } catch {
                throw error
            }
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

    private func buildRequest(url: URL, accessToken: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Bearer Token Authentication
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        // Headers
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("en", forHTTPHeaderField: "Accept-Language")

        // Timeouts
        request.timeoutInterval = 30.0
        return request
    }

    private func percentEncodedQuery(from parameters: [NatalChartRequest.QueryParameter]) -> String {
        parameters.map { parameter in
            let encodedName = parameter.name.addingPercentEncoding(withAllowedCharacters: .prokeralaQueryAllowed) ?? parameter.name
            let encodedValue = parameter.value.addingPercentEncoding(withAllowedCharacters: .prokeralaQueryAllowed) ?? parameter.value
            return "\(encodedName)=\(encodedValue)"
        }
        .joined(separator: "&")
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
                switch error {
                case .rateLimitExceeded, .serverError, .networkError:
                    lastError = error
                    if attempt < maxAttempts - 1 {
                        let delay = pow(2.0, Double(attempt)) // 1s, 2s, 4s
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    }
                case .authenticationFailed:
                    lastError = error
                    if attempt < maxAttempts - 1 {
                        // Token will be invalidated by caller; retry immediately
                        continue
                    }
                    throw error
                default:
                    throw error
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
    struct Source: Codable {
        let parameter: String?
    }

    let title: String
    let detail: String
    let code: String
    let source: Source?
}

// MARK: - OAuth Token Handling

private actor ProkeralaTokenManager {

    private struct TokenInfo {
        let accessToken: String
        let expiryDate: Date
        let tokenType: String
    }

    private let clientID: String
    private let clientSecret: String
    private let session: URLSessionProtocol
    private let tokenURL: URL
    private var cachedToken: TokenInfo?
    private let decoder: JSONDecoder

    init(
        clientID: String,
        clientSecret: String,
        session: URLSessionProtocol,
        tokenURL: URL = URL(string: "https://api.prokerala.com/token")!
    ) {
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.session = session
        self.tokenURL = tokenURL
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func accessToken() async throws -> String {
        if let cachedToken = cachedToken, cachedToken.expiryDate.timeIntervalSinceNow > 60 {
            return cachedToken.accessToken
        }

        let newToken = try await requestNewToken()
        cachedToken = newToken
        return newToken.accessToken
    }

    func invalidate() {
        cachedToken = nil
    }

    private func requestNewToken() async throws -> TokenInfo {
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        var body = URLComponents()
        body.queryItems = [
            URLQueryItem(name: "grant_type", value: "client_credentials"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "client_secret", value: clientSecret)
        ]
        request.httpBody = body.percentEncodedQuery?.data(using: .utf8)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AstroAPIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            let tokenResponse = try decoder.decode(ProkeralaTokenResponse.self, from: data)
            guard tokenResponse.tokenType.lowercased() == "bearer" else {
                throw AstroAPIError.invalidToken("Unsupported token type: \(tokenResponse.tokenType)")
            }
            let expiry = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
            return TokenInfo(
                accessToken: tokenResponse.accessToken,
                expiryDate: expiry,
                tokenType: tokenResponse.tokenType
            )
        case 400, 401, 403:
            if let errorResponse = try? decoder.decode(ProkeralaTokenErrorResponse.self, from: data) {
                let detail = errorResponse.errorDescription ?? errorResponse.error ?? "Authentication failed"
                throw AstroAPIError.authenticationFailed(detail)
            }
            throw AstroAPIError.authenticationFailed("Authentication failed with status \(httpResponse.statusCode)")
        case 429:
            let retryAfter = TimeInterval(httpResponse.value(forHTTPHeaderField: "Retry-After") ?? "60") ?? 60
            throw AstroAPIError.rateLimitExceeded(retryAfter: retryAfter)
        case 500...599:
            throw AstroAPIError.serverError(statusCode: httpResponse.statusCode)
        default:
            throw AstroAPIError.httpError(statusCode: httpResponse.statusCode)
        }
    }
}

private struct ProkeralaTokenResponse: Decodable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let scope: String?
}

private struct ProkeralaTokenErrorResponse: Decodable {
    let error: String?
    let errorDescription: String?
}

private extension CharacterSet {
    static let prokeralaQueryAllowed: CharacterSet = {
        var set = CharacterSet.urlQueryAllowed
        set.remove(charactersIn: "+&=")
        return set
    }()
}
