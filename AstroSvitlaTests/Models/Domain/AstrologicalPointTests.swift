import XCTest
@testable import AstroSvitla

final class AstrologicalPointTests: XCTestCase {

    func testInit_withValidValues_assignsDerivedSign() throws {
        let point = try AstrologicalPoint(pointType: .northNode, longitude: 47.23, housePlacement: 3)

        XCTAssertEqual(point.zodiacSign, .taurus)
        XCTAssertEqual(point.housePlacement, 3)
    }

    func testInit_withInvalidLongitude_throws() {
        XCTAssertThrowsError(try AstrologicalPoint(pointType: .northNode, longitude: 360.0, housePlacement: 3)) { error in
            guard case AstrologicalPoint.ValidationError.invalidLongitude = error else {
                return XCTFail("Expected invalidLongitude error, got \(error)")
            }
        }
    }

    func testInit_withInvalidHouse_throws() {
        XCTAssertThrowsError(try AstrologicalPoint(pointType: .northNode, longitude: 47.23, housePlacement: 0)) { error in
            guard case AstrologicalPoint.ValidationError.invalidHouse = error else {
                return XCTFail("Expected invalidHouse error, got \(error)")
            }
        }
    }
}
