import XCTest
import CoreLocation
@testable import AstroSvitla

final class AstrologyAPIContractTests: XCTestCase {

    func testNatalChartRequestIncludesNodesAndLilith() {
        let birthDetails = sampleBirthDetails()
        let request = AstrologyAPIDTOMapper.toAPIRequest(birthDetails: birthDetails)
        let activePoints = request.options.activePoints

        XCTAssertTrue(activePoints.contains("True Node"), "True Node must be requested from Astrology API")
        XCTAssertTrue(activePoints.contains("South Node"), "South Node must be requested from Astrology API")
        XCTAssertTrue(activePoints.contains("Lilith"), "Lilith must be requested from Astrology API")
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
