import Foundation
import SwiftData
import CoreLocation
import Sentry

enum ChartCalculatorError: LocalizedError, Equatable {
    case invalidTimeZone(String)
    case invalidHouseData
    case apiError(String)
    case noInternetConnection
    case rateLimitExceeded(retryAfter: Int)

    var errorDescription: String? {
        switch self {
        case .invalidTimeZone(let identifier):
            return "Invalid timezone identifier: \(identifier)"
        case .invalidHouseData:
            return "House calculation returned invalid data."
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
        case (.invalidHouseData, .invalidHouseData):
            return true
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

    private let natalChartService: NatalChartServiceProtocol?
    // private let ephemerisService: SwissEphemerisService?  // COMMENTED OUT - SwissEphemeris disabled for Free Astrology API testing

    /// Initialize with NatalChartService (Free Astrology API)
    init(natalChartService: NatalChartServiceProtocol) {
        self.natalChartService = natalChartService
        // self.ephemerisService = nil  // COMMENTED OUT
    }

    /* COMMENTED OUT - Legacy SwissEphemeris initializer disabled for Free Astrology API testing
    /// Legacy initializer with SwissEphemeris (deprecated)
    init(ephemerisService: SwissEphemerisService = SwissEphemerisService()) {
        self.ephemerisService = ephemerisService
        self.natalChartService = nil
    }
    */

    /// Convenience initializer with ModelContext for production use
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

        // Use Free Astrology API service
        guard let service = natalChartService else {
            SentrySDK.capture(message: "Unexpected: Chart service not initialized") { scope in
                scope.setLevel(.error)
                scope.setTag(value: "chart_calculation", key: "service")
                scope.setExtra(value: "natalChartService is nil", key: "error_details")
            }
            throw ChartCalculatorError.apiError("Chart service not initialized")
        }

        return try await calculateWithAPI(
            birthDate: birthDate,
            birthTime: birthTime,
            timeZoneIdentifier: timeZoneIdentifier,
            latitude: latitude,
            longitude: longitude,
            locationName: locationName
        )

        /* COMMENTED OUT - Swiss Ephemeris fallback disabled for Free Astrology API testing
        // Fallback to Swiss Ephemeris (legacy path)
        guard let ephemerisService = ephemerisService else {
            throw ChartCalculatorError.apiError("No calculation service available")
        }

        return try await calculateWithSwissEphemeris(
            birthDate: birthDate,
            birthTime: birthTime,
            timeZoneIdentifier: timeZoneIdentifier,
            latitude: latitude,
            longitude: longitude,
            locationName: locationName,
            ephemerisService: ephemerisService
        )
        */
    }

    // MARK: - API-based Calculation (New)

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

        guard let service = natalChartService else {
            SentrySDK.capture(message: "Unexpected: Chart service not initialized (duplicate check)") { scope in
                scope.setLevel(.error)
                scope.setTag(value: "chart_calculation", key: "service")
                scope.setExtra(value: "natalChartService is nil in calculateWithAPI", key: "error_details")
            }
            throw ChartCalculatorError.apiError("Chart service not initialized")
        }

        do {
            return try await service.generateChart(birthDetails: birthDetails, forceRefresh: false)
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

    // MARK: - Swiss Ephemeris Calculation (Legacy) - COMMENTED OUT

    /* COMMENTED OUT - SwissEphemeris calculation disabled for Free Astrology API testing
    private func calculateWithSwissEphemeris(
        birthDate: Date,
        birthTime: Date,
        timeZoneIdentifier: String,
        latitude: Double,
        longitude: Double,
        locationName: String,
        ephemerisService: SwissEphemerisService
    ) async throws -> NatalChart {

        let utcDate: Date
        do {
            utcDate = try ephemerisService.utcDate(
                birthDate: birthDate,
                birthTime: birthTime,
                timeZoneIdentifier: timeZoneIdentifier
            )
        } catch {
            throw ChartCalculatorError.invalidTimeZone(timeZoneIdentifier)
        }

        let houseResult = try ephemerisService.calculateHouses(
            at: utcDate,
            latitude: latitude,
            longitude: longitude
        )

        guard houseResult.houses.count == 12 else {
            throw ChartCalculatorError.invalidHouseData
        }

        let planets = try ephemerisService
            .calculatePlanets(at: utcDate)
            .map { assignHouse(for: $0, using: houseResult.houses) }

        let aspects = ephemerisService.calculateAspects(for: planets)

        return NatalChart(
            birthDate: birthDate,
            birthTime: birthTime,
            latitude: latitude,
            longitude: longitude,
            locationName: locationName,
            planets: planets,
            houses: houseResult.houses,
            aspects: aspects,
            ascendant: houseResult.ascendant,
            midheaven: houseResult.midheaven,
            calculatedAt: Date()
        )
    }

    private func assignHouse(for planet: Planet, using houses: [House]) -> Planet {
        guard let house = houseContaining(planetLongitude: planet.longitude, houses: houses) else {
            return planet
        }

        return Planet(
            id: planet.id,
            name: planet.name,
            longitude: planet.longitude,
            latitude: planet.latitude,
            sign: planet.sign,
            house: house.number,
            isRetrograde: planet.isRetrograde,
            speed: planet.speed
        )
    }

    private func houseContaining(planetLongitude: Double, houses: [House]) -> House? {
        let ordered = houses.sorted { $0.number < $1.number }

        for index in 0..<ordered.count {
            let current = ordered[index]
            let next = ordered[(index + 1) % ordered.count]

            if isLongitude(planetLongitude, between: current.cusp, and: next.cusp) {
                return current
            }
        }

        return ordered.first
    }

    private func isLongitude(_ value: Double, between start: Double, and end: Double) -> Bool {
        let normalizedValue = normalize(value)
        let normalizedStart = normalize(start)
        let normalizedEnd = normalize(end)

        if normalizedStart < normalizedEnd {
            return (normalizedStart...normalizedEnd).contains(normalizedValue)
        } else {
            return normalizedValue >= normalizedStart || normalizedValue <= normalizedEnd
        }
    }

    private func normalize(_ value: Double) -> Double {
        let normalized = value.truncatingRemainder(dividingBy: 360)
        return normalized >= 0 ? normalized : normalized + 360
    }
    */ // End of commented Swiss Ephemeris code
}
