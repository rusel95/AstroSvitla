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
            return "OpenAI API key is not configured. Update Config.swift to enable report generation."
        case .invalidResponse:
            return "OpenAI returned a response in an unexpected format."
        case .noContent:
            return "OpenAI returned an empty response."
        case .rateLimited:
            return "OpenAI rate limit exceeded. Please try again shortly."
        case .serviceUnavailable:
            return "OpenAI service is temporarily unavailable."
        case .network(let underlying):
            return "Network error: \(underlying.localizedDescription)"
        case .cancelled:
            return "Report generation was cancelled."
        }
    }
}
