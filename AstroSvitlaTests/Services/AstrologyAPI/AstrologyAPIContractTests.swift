import XCTest
import CoreLocation
@testable import AstroSvitla

@MainActor
final class AstrologyAPIContractTests: XCTestCase {

    func testNatalChartRequestIncludesNodesAndLilith() {
        let birthDetails = sampleBirthDetails()
        let request = AstrologyAPIDTOMapper.toAPIRequest(birthDetails: birthDetails)
        let activePoints = request.options.activePoints

        XCTAssertTrue(activePoints.contains("True Node"), "True Node must be requested from Astrology API")
        XCTAssertTrue(activePoints.contains("South Node"), "South Node must be requested from Astrology API")
        XCTAssertTrue(activePoints.contains("Lilith"), "Lilith must be requested from Astrology API")
    }

    /// T005 [Story US1]: Validates that astrology-api.io response includes True Node, South Node, and Lilith
    /// with accurate positions (within 1° of expected values) and that these points are persisted in cache.
    func testNodesAndLilithMapping() throws {
        // Load the canonical fixture from specs/005-enhance-astrological-report/contracts/fixtures/
        // Use absolute path from project root
        let fixtureURL = URL(fileURLWithPath: "/Users/Ruslan_Popesku/Desktop/AstroSvitla/specs/005-enhance-astrological-report/contracts/fixtures/natal-chart-sample.json")

        let fixtureData = try Data(contentsOf: fixtureURL)
        let apiResponse = try JSONDecoder().decode(AstrologyAPINatalChartResponse.self, from: fixtureData)

        // Expected positions from fixture:
        // True Node: Tau 17.12° (abs_pos: 47.12)
        // Lilith: Vir 24.63° (abs_pos: 174.63)
        let expectedTrueNodeLongitude = 47.12
        let expectedLilithLongitude = 174.63

        // Map the response to domain model
        let birthDetails = fixtureBirthDetails()
        let natalChart = try AstrologyAPIDTOMapper.toDomainModel(
            response: apiResponse,
            birthDetails: birthDetails
        )

        // Assert True Node presence and accuracy (within 1°)
        guard let trueNode = natalChart.planets.first(where: { $0.name == .trueNode }) else {
            XCTFail("True Node must be present in mapped natal chart")
            return
        }
        XCTAssertEqual(trueNode.longitude, expectedTrueNodeLongitude, accuracy: 1.0,
                      "True Node longitude must match fixture within 1°")
        XCTAssertEqual(trueNode.sign, .taurus, "True Node must be in Taurus")
        XCTAssertEqual(trueNode.house, 3, "True Node must be in 3rd house")

        // Assert South Node is computed (opposite True Node)
        guard let southNode = natalChart.planets.first(where: { $0.name == .southNode }) else {
            XCTFail("South Node must be computed from True Node")
            return
        }
        let expectedSouthNodeLongitude = (expectedTrueNodeLongitude + 180).truncatingRemainder(dividingBy: 360)
        XCTAssertEqual(southNode.longitude, expectedSouthNodeLongitude, accuracy: 1.0,
                      "South Node must be opposite True Node (±180°)")
        XCTAssertEqual(southNode.sign, .scorpio, "South Node must be in Scorpio (opposite Taurus)")

        // Assert Lilith presence and accuracy
        guard let lilith = natalChart.planets.first(where: { $0.name == .lilith }) else {
            XCTFail("Lilith must be present in mapped natal chart")
            return
        }
        XCTAssertEqual(lilith.longitude, expectedLilithLongitude, accuracy: 1.0,
                      "Lilith longitude must match fixture within 1°")
        XCTAssertEqual(lilith.sign, .virgo, "Lilith must be in Virgo")
        XCTAssertEqual(lilith.house, 6, "Lilith must be in 6th house")

        // TODO: Assert cache persistence once ChartCacheService is integrated with new mapper
        // For now, verify the domain model is complete and ready for caching
        XCTAssertGreaterThanOrEqual(natalChart.planets.count, 12,
                                   "Natal chart must include 10 traditional planets + True Node + Lilith")
    }

    private func fixtureBirthDetails() -> BirthDetails {
        // Birth details matching natal-chart-sample.json fixture
        var dateComponents = DateComponents()
        dateComponents.year = 1990
        dateComponents.month = 3
        dateComponents.day = 25
        let birthDate = Calendar(identifier: .gregorian).date(from: dateComponents) ?? Date()

        var timeComponents = DateComponents()
        timeComponents.hour = 14
        timeComponents.minute = 30
        let birthTime = Calendar(identifier: .gregorian).date(from: timeComponents) ?? Date()

        return BirthDetails(
            name: "Sample Chart",
            birthDate: birthDate,
            birthTime: birthTime,
            location: "Kyiv, Ukraine",
            timeZone: TimeZone(identifier: "Europe/Kyiv") ?? .current,
            coordinate: CLLocationCoordinate2D(latitude: 50.4501, longitude: 30.5234)
        )
    }

    private func sampleBirthDetails() -> BirthDetails {
        var dateComponents = DateComponents()
        dateComponents.year = 1990
        dateComponents.month = 4
        dateComponents.day = 15
        let birthDate = Calendar(identifier: .gregorian).date(from: dateComponents) ?? Date()

        var timeComponents = DateComponents()
        timeComponents.hour = 14
        timeComponents.minute = 30
        let birthTime = Calendar(identifier: .gregorian).date(from: timeComponents) ?? Date()

        return BirthDetails(
            name: "Test",
            birthDate: birthDate,
            birthTime: birthTime,
            location: "Kyiv, Ukraine",
            timeZone: TimeZone(secondsFromGMT: 3 * 3600) ?? .current,
            coordinate: CLLocationCoordinate2D(latitude: 50.4501, longitude: 30.5234)
        )
    }
}
