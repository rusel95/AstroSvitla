import Foundation

enum ReportGenerationError: Error, LocalizedError {
    case missingAPIKey
    case invalidResponse
    case noContent
    case rateLimited
    case serviceUnavailable
    case network(underlying: Error)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return String(localized: "error.api.missing_key")
        case .invalidResponse:
            return String(localized: "error.api.invalid_response")
        case .noContent:
            return String(localized: "error.api.no_content")
        case .rateLimited:
            return String(localized: "error.api.rate_limited")
        case .serviceUnavailable:
            return String(localized: "error.api.unavailable")
        case .network(let underlying):
            return String(localized: "error.network \(underlying.localizedDescription)")
        case .cancelled:
            return String(localized: "error.cancelled")
        }
    }
}
