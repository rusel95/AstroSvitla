import Foundation
import CoreGraphics

/// Utility for processing SVG strings, particularly for handling specific chart formats
struct SvgChartProcessor {
    
    struct ProcessingResult {
        let svgString: String
        let dimensions: CGSize
        let shouldCropToSquare: Bool
    }
    
    /// Processes an SVG string to handle specific chart formats (like Kerykeion)
    /// and returns the processed string and dimensions.
    static func process(svg: String) -> ProcessingResult {
        var dimensions = extractDimensions(from: svg)
        var processedSvg = svg
        var shouldCrop = false
        
        // Logic: If image is significantly wider than tall (>1.2), assume it has side bars
        // Example: Kerykeion output is 820x550, but the wheel is 550x550 centered/left.
        if dimensions.width > dimensions.height * 1.2 {
            // Check for known Kerykeion wide format
            if svg.contains("viewBox=\"0 0 820 550.0\"") {
                processedSvg = svg.replacingOccurrences(of: "viewBox=\"0 0 820 550.0\"", with: "viewBox=\"0 0 550 550.0\"")
                dimensions = CGSize(width: 550, height: 550)
                shouldCrop = true
            } else if svg.contains("viewBox=\"0 0 800 600\"") {
                // Another potential wide format
                processedSvg = svg.replacingOccurrences(of: "viewBox=\"0 0 800 600\"", with: "viewBox=\"0 0 600 600\"")
                dimensions = CGSize(width: 600, height: 600)
                shouldCrop = true
            }
        }
        
        return ProcessingResult(
            svgString: processedSvg,
            dimensions: dimensions,
            shouldCropToSquare: shouldCrop
        )
    }
    
    /// Extract dimensions from SVG viewBox or width/height attributes
    static func extractDimensions(from svg: String) -> CGSize {
        // Try to extract viewBox first (e.g., viewBox="0 0 800 800")
        if let viewBoxRegex = try? NSRegularExpression(pattern: #"viewBox\s*=\s*"([^"]+)""#),
           let match = viewBoxRegex.firstMatch(in: svg, range: NSRange(svg.startIndex..., in: svg)),
           let viewBoxRange = Range(match.range(at: 1), in: svg) {
            let viewBoxString = String(svg[viewBoxRange])
            let values = viewBoxString.split(separator: " ").compactMap { Double($0) }
            if values.count == 4 {
                let width = values[2]
                let height = values[3]
                return CGSize(width: width, height: height)
            }
        }
        
        // Try to extract width and height attributes
        var width: Double?
        var height: Double?
        
        if let widthRegex = try? NSRegularExpression(pattern: #"width\s*=\s*"([^"]+)""#),
           let match = widthRegex.firstMatch(in: svg, range: NSRange(svg.startIndex..., in: svg)),
           let widthRange = Range(match.range(at: 1), in: svg) {
            let widthString = String(svg[widthRange]).replacingOccurrences(of: "px", with: "")
            width = Double(widthString)
        }
        
        if let heightRegex = try? NSRegularExpression(pattern: #"height\s*=\s*"([^"]+)""#),
           let match = heightRegex.firstMatch(in: svg, range: NSRange(svg.startIndex..., in: svg)),
           let heightRange = Range(match.range(at: 1), in: svg) {
            let heightString = String(svg[heightRange]).replacingOccurrences(of: "px", with: "")
            height = Double(heightString)
        }
        
        if let w = width, let h = height {
            return CGSize(width: w, height: h)
        }
        
        // Default to square if dimensions can't be extracted
        return CGSize(width: 800, height: 800)
    }
}
