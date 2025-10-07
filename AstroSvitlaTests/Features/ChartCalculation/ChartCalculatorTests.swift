import Foundation
@testable import AstroSvitla
import Testing

struct ChartCalculatorTests {

    private let calculator = ChartCalculator()

    @Test
    func testCalculateProducesPlanetsHousesAndAspects() throws {
        let latitude = 50.4501
        let longitude = 30.5234

        let birthDate = ISO8601DateFormatter().date(from: "1990-04-15T00:00:00Z")!
        let birthTime = ISO8601DateFormatter().date(from: "1990-04-15T14:30:00Z")!

        let result = try calculator.calculate(
            birthDate: birthDate,
            birthTime: birthTime,
            timeZoneIdentifier: "Europe/Kyiv",
            latitude: latitude,
            longitude: longitude,
            locationName: "Kyiv, Ukraine"
        )

        #expect(result.planets.count == PlanetType.allCases.count)
        #expect(result.houses.count == 12)
        #expect(result.ascendant >= 0 && result.ascendant < 360)
        #expect(result.midheaven >= 0 && result.midheaven < 360)
        #expect(result.planets.allSatisfy { (1...12).contains($0.house) })
        #expect(result.locationName == "Kyiv, Ukraine")
    }

    @Test
    func testCalculateThrowsOnInvalidTimezone() {
        let birthDate = ISO8601DateFormatter().date(from: "1990-04-15T00:00:00Z")!
        let birthTime = ISO8601DateFormatter().date(from: "1990-04-15T14:30:00Z")!

        #expect(throws: ChartCalculatorError.invalidTimeZone("Mars/Base")) {
            _ = try calculator.calculate(
                birthDate: birthDate,
                birthTime: birthTime,
                timeZoneIdentifier: "Mars/Base",
                latitude: 0,
                longitude: 0,
                locationName: "Mars"
            )
        }
    }
}
