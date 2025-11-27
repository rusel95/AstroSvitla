//
//  AstrologyAPIService.swift
//  AstroSvitla
//
//  Created by AstrologyAPI Integration
//  HTTP client for api.astrology-api.io
//

import Foundation
import Sentry

/// Service errors for AstrologyAPI communication
enum AstrologyAPIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodingError(Error)
    case rateLimitExceeded(retryAfter: TimeInterval)
    case invalidBirthDetails
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from API"
        case .httpError(let statusCode, let message):
            return "HTTP error \(statusCode): \(message ?? "Unknown error")"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .rateLimitExceeded(let retryAfter):
            return "Rate limit exceeded. Retry after \(Int(retryAfter)) seconds"
        case .invalidBirthDetails:
            return "Invalid birth details provided"
        }
    }
}

/// Main service for communicating with api.astrology-api.io
@MainActor
final class AstrologyAPIService: NSObject {
    
    // MARK: - Properties
    
    private let baseURL: String
    private let session: URLSession
    private let requestTimeout: TimeInterval
    private let rateLimiter: RateLimiter
    
    // MARK: - Initialization
    
    init(
        baseURL: String? = nil,
        session: URLSession? = nil,
        rateLimiter: RateLimiter? = nil
    ) {
        self.baseURL = baseURL ?? Config.astrologyAPIBaseURL
        self.requestTimeout = Config.astrologyAPIRequestTimeout
        // AstrologyAPI has a limit of 10 requests per 60 seconds
        self.rateLimiter = rateLimiter ?? RateLimiter(
            maxRequestsPerWindow: 10,
            windowInterval: 60,
            requestsPerChart: 1  // Single endpoint for natal chart
        )
        
        // Use provided session or create one with SSL bypass for DEBUG in corporate networks
        if let providedSession = session {
            self.session = providedSession
        } else {
            #if DEBUG
            // In DEBUG mode, allow self-signed/corporate proxy certificates
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = Config.astrologyAPIRequestTimeout
            // Create a delegate that bypasses SSL validation in DEBUG
            let delegate = SSLBypassDelegate()
            self.session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
            #else
            self.session = .shared
            #endif
        }
        
        super.init()
    }
    
    // MARK: - Public API
    
    /// Generate a natal chart using the api.astrology-api.io API
    /// - Parameter birthDetails: Birth information for chart calculation
    /// - Returns: Complete natal chart with planets, houses, and aspects
    /// - Throws: AstrologyAPIError if the request fails
    func generateNatalChart(
        birthDetails: BirthDetails
    ) async throws -> NatalChart {
        // Check rate limit before making request
        let (allowed, retryAfter) = rateLimiter.canMakeRequest()
        if !allowed {
            throw AstrologyAPIError.rateLimitExceeded(retryAfter: retryAfter ?? 60)
        }
        
        // Build request
        let request = try buildNatalChartRequest(birthDetails: birthDetails)
        
        // Record request for rate limiting
        rateLimiter.recordRequest()
        
        // Execute request
        let (data, httpResponse) = try await executeRequest(request)
        // Validate response
        try validateHTTPResponse(httpResponse)
        // Decode response
        let response: AstrologyAPINatalChartResponse
        do {
            response = try JSONDecoder().decode(AstrologyAPINatalChartResponse.self, from: data)
        } catch {
            throw AstrologyAPIError.decodingError(error)
        }
        // Map to domain model
        return try AstrologyAPIDTOMapper.toDomain(response: response, birthDetails: birthDetails)
    }
    
    /// Generate an SVG chart visualization using the api.astrology-api.io API
    /// - Parameters:
    ///   - birthDetails: Birth information for chart calculation
    ///   - theme: Visual theme ("classic", "dark", etc.)
    ///   - language: Language code for labels ("en", "uk", etc.)
    /// - Returns: SVG content as a string
    /// - Throws: AstrologyAPIError if the request fails
    func generateChartSVG(
        birthDetails: BirthDetails,
        theme: String = "classic",
        language: String = "en"
    ) async throws -> String {
        // Build request
        let request = try buildSVGRequest(birthDetails: birthDetails, theme: theme, language: language)
        // Execute request
        let (data, httpResponse) = try await executeRequest(request)
        // Validate response
        try validateHTTPResponse(httpResponse)
        // Try to decode as JSON first (if API returns {"svg": "..."})
        if let jsonResponse = try? JSONDecoder().decode(AstrologyAPISVGResponse.self, from: data) {
            return jsonResponse.svgContent
        }
        // Otherwise, treat response as plain SVG text
        guard let svgString = String(data: data, encoding: .utf8) else {
            throw AstrologyAPIError.decodingError(
                NSError(domain: "AstrologyAPI", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "SVG response is not valid UTF-8 text"
                ])
            )
        }
        return svgString
    }
    
    // MARK: - Private Methods
    
    private func buildNatalChartRequest(birthDetails: BirthDetails) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)/charts/natal") else {
            throw AstrologyAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue("Bearer \(Config.astrologyAPIKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = requestTimeout

        let requestBody = AstrologyAPIDTOMapper.toAPIRequest(birthDetails: birthDetails)
        request.httpBody = try JSONEncoder().encode(requestBody)

        return request
    }
    
    private func buildSVGRequest(
        birthDetails: BirthDetails,
        theme: String,
        language: String
    ) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)/svg/natal") else {
            throw AstrologyAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue("Bearer \(Config.astrologyAPIKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = requestTimeout

        let requestBody = AstrologyAPIDTOMapper.toSVGRequest(
            birthDetails: birthDetails,
            theme: theme,
            language: language
        )
        request.httpBody = try JSONEncoder().encode(requestBody)

        return request
    }
    
    private func executeRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response): (Data, URLResponse)
        
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AstrologyAPIError.networkError(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AstrologyAPIError.invalidResponse
        }
        
        return (data, httpResponse)
    }
    
    private func validateHTTPResponse(_ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200...299:
            return // Success
        case 429:
            throw AstrologyAPIError.rateLimitExceeded(retryAfter: 60)
        case 400...499:
            throw AstrologyAPIError.httpError(statusCode: response.statusCode, message: "Client error")
        case 500...599:
            throw AstrologyAPIError.httpError(statusCode: response.statusCode, message: "Server error")
        default:
            SentrySDK.capture(message: "Unexpected HTTP status code from Astrology API") { scope in
                scope.setLevel(.warning)
                scope.setTag(value: "astrology_api", key: "service")
                scope.setExtra(value: response.statusCode, key: "status_code")
                scope.setExtra(value: response.url?.absoluteString ?? "unknown", key: "url")
            }
            throw AstrologyAPIError.httpError(statusCode: response.statusCode, message: "Unexpected status code")
        }
    }
}

// MARK: - SSL Bypass Delegate (DEBUG only)

#if DEBUG
/// URLSession delegate that bypasses SSL certificate validation
/// ⚠️ WARNING: This is for DEBUG builds only to work around corporate proxy/firewall SSL inspection
/// This should NEVER be used in production builds
final class SSLBypassDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate, @unchecked Sendable {
    
    // Session-level challenge handler
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        handleChallenge(challenge, completionHandler: completionHandler)
    }
    
    // Task-level challenge handler (needed for some iOS versions)
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        handleChallenge(challenge, completionHandler: completionHandler)
    }
    
    private func handleChallenge(
        _ challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        let host = challenge.protectionSpace.host
        
        // Only bypass for server trust challenges (SSL)
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            
            // Disable all SSL validation for this trust
            SecTrustSetAnchorCertificates(serverTrust, [] as CFArray)
            SecTrustSetAnchorCertificatesOnly(serverTrust, false)
            
            // Accept the server's certificate regardless of validation
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
            print("[SSLBypassDelegate] ⚠️ Bypassing SSL validation for: \(host)")
        } else {
            // For other challenges, use default handling
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
#endif
