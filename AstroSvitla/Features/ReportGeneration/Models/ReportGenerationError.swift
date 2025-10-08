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
            return "Ключ OpenAI API не налаштовано. Оновіть Config.swift, щоб увімкнути генерацію звітів."
        case .invalidResponse:
            return "OpenAI повернув відповідь у неочікуваному форматі."
        case .noContent:
            return "OpenAI повернув порожню відповідь."
        case .rateLimited:
            return "Перевищено ліміт запитів OpenAI. Спробуйте знову трохи пізніше."
        case .serviceUnavailable:
            return "Сервіс OpenAI тимчасово недоступний."
        case .network(let underlying):
            return "Помилка мережі: \(underlying.localizedDescription)"
        case .cancelled:
            return "Генерацію звіту скасовано."
        }
    }
}
