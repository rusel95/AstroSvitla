import XCTest
import SwiftDraw
@testable import AstroSvitla

final class SvgChartProcessorTests: XCTestCase {

    func testProcessFixesMalformedComments() {
        let svg = "<!--- This is a comment --><svg></svg>"
        let result = SvgChartProcessor.process(svg: svg)
        XCTAssertTrue(result.contains("<!-- This is a comment -->"))
        XCTAssertFalse(result.contains("<!---"))
    }
    
    func testProcessRemovesXmlDeclaration() {
        let svg = "<?xml version='1.0' encoding='UTF-8'?><svg></svg>"
        let result = SvgChartProcessor.process(svg: svg)
        XCTAssertFalse(result.contains("<?xml"))
        XCTAssertTrue(result.hasPrefix("<svg>"))
    }
    
    func testProcessConvertsSingleToDoubleQuotes() {
        let svg = "<svg xmlns='http://www.w3.org/2000/svg'></svg>"
        let result = SvgChartProcessor.process(svg: svg)
        XCTAssertTrue(result.contains("xmlns=\"http://www.w3.org/2000/svg\""))
    }
    
    func testSwiftDrawCanParseExampleSVG() throws {
        // Load the example SVG from the test fixtures
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "example", withExtension: "svg") else {
            XCTFail("Could not find example.svg in test bundle")
            return
        }
        
        let originalSvg = try String(contentsOf: url, encoding: .utf8)
        print("Original SVG size: \(originalSvg.count) bytes")
        print("First 500 chars: \(originalSvg.prefix(500))")
        
        // Process the SVG
        let processedSvg = SvgChartProcessor.process(svg: originalSvg)
        print("Processed SVG size: \(processedSvg.count) bytes")
        print("First 500 chars after processing: \(processedSvg.prefix(500))")
        
        // Try to parse with SwiftDraw
        guard let svgData = processedSvg.data(using: .utf8) else {
            XCTFail("Could not convert SVG to data")
            return
        }
        
        let svg = SVG(data: svgData)
        XCTAssertNotNil(svg, "SwiftDraw should be able to parse the processed SVG")
        
        if let svg = svg {
            let image = svg.rasterize()
            XCTAssertGreaterThan(image.size.width, 0)
            XCTAssertGreaterThan(image.size.height, 0)
            print("Rasterized to: \(image.size)")
        }
    }
}
