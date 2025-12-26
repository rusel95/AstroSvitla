import Foundation
import SwiftData
import CoreLocation

enum ChartCalculatorError: LocalizedError, Equatable {
    case invalidTimeZone(String)
    case apiError(String)
    case noInternetConnection
    case rateLimitExceeded(retryAfter: Int)

    var errorDescription: String? {
        switch self {
        case .invalidTimeZone(let identifier):
            return "Invalid timezone identifier: \(identifier)"
        case .apiError(let message):
            return message
        case .noInternetConnection:
            return "Unable to connect. Please check your internet connection."
        case .rateLimitExceeded(let seconds):
            return "Request limit reached. Please wait \(seconds) seconds before trying again."
        }
    }

    static func == (lhs: ChartCalculatorError, rhs: ChartCalculatorError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidTimeZone(let l), .invalidTimeZone(let r)):
            return l == r
        case (.apiError(let l), .apiError(let r)):
            return l == r
        case (.noInternetConnection, .noInternetConnection):
            return true
        case (.rateLimitExceeded(let l), .rateLimitExceeded(let r)):
            return l == r
        default:
            return false
        }
    }
}

final class ChartCalculator {

    private let natalChartService: NatalChartServiceProtocol

    /// Initialize with a natal chart service implementation.
    init(natalChartService: NatalChartServiceProtocol) {
        self.natalChartService = natalChartService
    }

    /// Convenience initializer with ModelContext for production use.
    convenience init(modelContext: ModelContext) {
        let service = NatalChartService(modelContext: modelContext)
        self.init(natalChartService: service)
    }

    func calculate(
        birthDate: Date,
        birthTime: Date,
        timeZoneIdentifier: String,
        latitude: Double,
        longitude: Double,
        locationName: String
    ) async throws -> NatalChart {
        return try await calculateWithAPI(
            birthDate: birthDate,
            birthTime: birthTime,
            timeZoneIdentifier: timeZoneIdentifier,
            latitude: latitude,
            longitude: longitude,
            locationName: locationName
        )
    }

    // MARK: - API-based Calculation

    private func calculateWithAPI(
        birthDate: Date,
        birthTime: Date,
        timeZoneIdentifier: String,
        latitude: Double,
        longitude: Double,
        locationName: String
    ) async throws -> NatalChart {

        guard let timeZone = TimeZone(identifier: timeZoneIdentifier) else {
            throw ChartCalculatorError.invalidTimeZone(timeZoneIdentifier)
        }

        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        let birthDetails = BirthDetails(
            name: "", // Not required for chart calculation
            birthDate: birthDate,
            birthTime: birthTime,
            location: locationName,
            timeZone: timeZone,
            coordinate: coordinate
        )

        do {
            return try await natalChartService.generateChart(birthDetails: birthDetails, forceRefresh: false)
        } catch let error as NatalChartService.ServiceError {
            // Map service errors to calculator errors
            switch error {
            case .noInternetConnection:
                throw ChartCalculatorError.noInternetConnection
            case .rateLimitExceeded(let retryAfter):
                throw ChartCalculatorError.rateLimitExceeded(retryAfter: Int(retryAfter))
            case .chartGenerationFailed(let underlyingError):
                throw ChartCalculatorError.apiError(underlyingError.localizedDescription)
            case .imageDownloadFailed:
                throw ChartCalculatorError.apiError("Chart generated but image unavailable")
            case .cachingFailed:
                throw ChartCalculatorError.apiError("Chart generated but could not be cached")
            case .noCachedDataAvailable:
                throw ChartCalculatorError.noInternetConnection
            }
        } catch {
            throw ChartCalculatorError.apiError(error.localizedDescription)
        }
    }
}
