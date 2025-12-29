import Foundation

/// Minimal SVG processor - no longer needed as we render raw SVG via WebView
struct SvgChartProcessor {
    
    /// Fixed chart dimensions from Kerykeion API
    static let chartWidth: CGFloat = 820
    static let chartHeight: CGFloat = 550
    static let aspectRatio: CGFloat = chartWidth / chartHeight
    
    /// Returns SVG unchanged - WebView handles rendering natively
    static func process(svg: String) -> String {
        return svg
    }
}
