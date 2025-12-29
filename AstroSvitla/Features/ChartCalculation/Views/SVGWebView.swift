import SwiftUI
import WebKit

/// A SwiftUI view that renders SVG content using WKWebView at fixed 820x550 dimensions
struct SVGWebView: UIViewRepresentable {
    let svgData: Data
    
    /// Fixed chart dimensions from Kerykeion API
    static let chartWidth: CGFloat = 820
    static let chartHeight: CGFloat = 550
    static let aspectRatio: CGFloat = chartWidth / chartHeight
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.suppressesIncrementalRendering = true
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .white
        webView.scrollView.backgroundColor = .white
        
        // Disable zoom
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let svgString = String(data: svgData, encoding: .utf8) else {
            return
        }
        
        // Use viewport-fit and scale properly
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, shrink-to-fit=yes">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body {
                    width: 100%;
                    height: 100%;
                    overflow: hidden;
                    background: white;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }
                svg {
                    width: 100%;
                    height: 100%;
                    max-width: 100%;
                    max-height: 100%;
                    display: block;
                }
            </style>
        </head>
        <body>
            \(svgString)
        </body>
        </html>
        """
        
        webView.loadHTMLString(html, baseURL: nil)
    }
}

// MARK: - Previews

#Preview("Simple SVG") {
    SVGWebView(svgData: """
    <svg viewBox="0 0 820 550" xmlns="http://www.w3.org/2000/svg">
        <rect fill="#f0f0f0" width="820" height="550"/>
        <circle cx="410" cy="275" r="200" fill="none" stroke="#ff0000" stroke-width="2"/>
        <text x="410" y="285" text-anchor="middle" font-size="24">Natal Chart Preview</text>
    </svg>
    """.data(using: .utf8)!)
        .aspectRatio(SVGWebView.aspectRatio, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .padding()
}

#Preview("Example SVG from File") {
    // Load example.svg from the project
    // Note: The file must be added to the app target's "Copy Bundle Resources" build phase
    if let url = Bundle.main.url(forResource: "example", withExtension: "svg"),
       let data = try? Data(contentsOf: url) {
        SVGWebView(svgData: data)
            .aspectRatio(SVGWebView.aspectRatio, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .padding()
    } else {
        // Fallback if file not found in bundle - try loading from project path
        let projectPath = "/Users/Ruslan_Popesku/Desktop/AstroSvitla/AstroSvitlaTests/example.svg"
        if let data = try? Data(contentsOf: URL(fileURLWithPath: projectPath)) {
            SVGWebView(svgData: data)
                .aspectRatio(SVGWebView.aspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .padding()
        } else {
            Text("example.svg not found")
                .foregroundStyle(.red)
        }
    }
}
