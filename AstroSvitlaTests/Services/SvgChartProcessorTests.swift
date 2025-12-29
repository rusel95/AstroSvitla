import XCTest
@testable import AstroSvitla

final class SvgChartProcessorTests: XCTestCase {

    func testExtractDimensions_viewBox() {
        let svg = "<svg viewBox=\"0 0 1200 800\"></svg>"
        let dimensions = SvgChartProcessor.extractDimensions(from: svg)
        
        XCTAssertEqual(dimensions.width, 1200)
        XCTAssertEqual(dimensions.height, 800)
    }
    
    func testExtractDimensions_widthHeight() {
        let svg = "<svg width=\"500px\" height=\"300px\"></svg>"
        let dimensions = SvgChartProcessor.extractDimensions(from: svg)
        
        XCTAssertEqual(dimensions.width, 500)
        XCTAssertEqual(dimensions.height, 300)
    }
    
    func testProcessing_wideKerykeionFormat_shouldCrop() {
        // This simulates the chart structure that the user is reporting issues with
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 820 550.0" width="100%" height="100%">
          <title> | Kerykeion</title>
          <g>Chart Content</g>
        </svg>
        """
        
        let result = SvgChartProcessor.process(svg: svg)
        
        // Should detect crop needed
        XCTAssertTrue(result.shouldCropToSquare)
        
        // Should have updated dimension extraction to reflect *original* dimensions (or new? the processor returns original dimensions but modifies SVG)
        // Actually the logic is: extract dimensions -> check ratio -> replace string.
        // The returned dimensions in 'result' are the *extracted* dimensions from input.
        XCTAssertEqual(result.dimensions.width, 820)
        
        // But the SVG string should now have the new viewBox
        XCTAssertTrue(result.svgString.contains("viewBox=\"0 0 550 550.0\""))
        XCTAssertFalse(result.svgString.contains("viewBox=\"0 0 820 550.0\""))
    }
    
    func testProcessing_standardSquare_shouldNotCrop() {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 550 550.0">
          <g>Chart</g>
        </svg>
        """
        
        let result = SvgChartProcessor.process(svg: svg)
        
        XCTAssertFalse(result.shouldCropToSquare)
        XCTAssertEqual(result.svgString, svg)
    }
    
    func testProcessing_unknownWideFormat_shouldNotCrop() {
        // A wide format that we don't know how to handle specifically
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 2000 550.0">
          <g>Unknown Chart</g>
        </svg>
        """
        
        let result = SvgChartProcessor.process(svg: svg)
        
        // Should be ignored unless we add specific handling
        XCTAssertFalse(result.shouldCropToSquare)
        XCTAssertEqual(result.svgString, svg)
    }
    
    func testProcessing_alternativeWideFormat_shouldCrop() {
            let svg = """
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 600">
              <g>Chart</g>
            </svg>
            """
            
            let result = SvgChartProcessor.process(svg: svg)
            
            XCTAssertTrue(result.shouldCropToSquare)
            XCTAssertTrue(result.svgString.contains("viewBox=\"0 0 600 600\""))
        }

}
