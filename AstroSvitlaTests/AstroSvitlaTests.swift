import XCTest
@testable import AstroSvitla

final class AstroSvitlaTests: XCTestCase {

    func testSvgChartProcessorReturnsUnchangedSVG() {
        let svg = "<svg viewBox=\"0 0 820 550\"></svg>"
        let result = SvgChartProcessor.process(svg: svg)
        XCTAssertEqual(result, svg)
    }
}
