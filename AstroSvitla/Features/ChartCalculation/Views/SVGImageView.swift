import SwiftUI
import WebKit

#if canImport(UIKit)
import UIKit
#endif

/// Renders SVG data by converting it to PNG using WKWebView
/// This approach handles complex SVG features (gradients, filters, fonts) that native SVG parsers may not support
struct SVGImageView: View {
    let svgData: Data
    
    @State private var renderedImage: Image?
    @State private var isLoading = true
    @State private var webViewController: SVGWebViewController?
    @State private var imageAspectRatio: CGFloat = 1.0  // Track actual image aspect ratio

    var body: some View {
        VStack(spacing: 0) {
            if let image = renderedImage {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
            } else if isLoading {
                ProgressView("Рендеринг")
                    .frame(maxWidth: .infinity)
                    .frame(height: 400)  // Placeholder height while loading
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundStyle(.orange)
                    
                    Text("Помилка рендерингу")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 400)  // Placeholder height for error
            }
        }
        .background(Color.white)
        .task {
            await renderSVG()
        }
    }
    
    @MainActor
    private func renderSVG() async {
        print("[SVGImageView] 🎨 Starting SVG to PNG conversion (\(svgData.count) bytes)")
        
        // Debug: Check first 200 bytes
        if let preview = String(data: svgData.prefix(200), encoding: .utf8) {
            print("[SVGImageView] 📄 SVG preview: \(preview)")
        }
        
        guard let svgString = String(data: svgData, encoding: .utf8) else {
            print("[SVGImageView] ❌ Invalid SVG data (not UTF-8)")
            isLoading = false
            return
        }
        
        // Create web view controller to render SVG
        let controller = SVGWebViewController()
        self.webViewController = controller
        
        do {
            // Extract SVG dimensions or use default
            let dimensions = extractSVGDimensions(from: svgString)
            let renderSize = CGSize(width: 1200, height: 1200 * (dimensions.height / dimensions.width))
            
            let image = try await controller.renderSVGToImage(svg: svgString, size: renderSize)
            self.renderedImage = Image(uiImage: image)
            self.isLoading = false
            print("[SVGImageView] ✅ SVG converted to PNG successfully: \(image.size)")
        } catch {
            print("[SVGImageView] ❌ SVG to PNG conversion failed: \(error.localizedDescription)")
            self.isLoading = false
        }
        
        // Clean up
        self.webViewController = nil
    }
    
    /// Extract dimensions from SVG viewBox or width/height attributes
    private func extractSVGDimensions(from svg: String) -> CGSize {
        // Try to extract viewBox first (e.g., viewBox="0 0 800 800")
        if let viewBoxRegex = try? NSRegularExpression(pattern: #"viewBox\s*=\s*"([^"]+)""#),
           let match = viewBoxRegex.firstMatch(in: svg, range: NSRange(svg.startIndex..., in: svg)),
           let viewBoxRange = Range(match.range(at: 1), in: svg) {
            let viewBoxString = String(svg[viewBoxRange])
            let values = viewBoxString.split(separator: " ").compactMap { Double($0) }
            if values.count == 4 {
                let width = values[2]
                let height = values[3]
                print("[SVGImageView] 📐 Extracted viewBox dimensions: \(width)x\(height)")
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
            print("[SVGImageView] 📐 Extracted width/height attributes: \(w)x\(h)")
            return CGSize(width: w, height: h)
        }
        
        // Default to square if dimensions can't be extracted
        print("[SVGImageView] ⚠️ Could not extract dimensions, using default 800x800")
        return CGSize(width: 800, height: 800)
    }
}

// MARK: - Web View Controller

/// Helper class to render SVG using WKWebView and capture as image
@MainActor
class SVGWebViewController: NSObject, WKNavigationDelegate {
    private var webView: WKWebView?
    private var continuation: CheckedContinuation<UIImage, Error>?
    
    enum RenderError: LocalizedError {
        case webViewLoadFailed
        case snapshotFailed
        case timeout
        
        var errorDescription: String? {
            switch self {
            case .webViewLoadFailed:
                return "WebView failed to load SVG"
            case .snapshotFailed:
                return "Failed to capture SVG as image"
            case .timeout:
                return "SVG rendering timed out"
            }
        }
    }
    
    func renderSVGToImage(svg: String, size: CGSize, timeout: TimeInterval = 10.0) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            // Create HTML wrapper
            let html = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    * { margin: 0; padding: 0; }
                    html, body {
                        width: \(size.width)px;
                        height: \(size.height)px;
                        overflow: hidden;
                        background: white;
                    }
                    svg {
                        width: 100%;
                        height: 100%;
                        display: block;
                    }
                </style>
            </head>
            <body>
                \(svg)
            </body>
            </html>
            """
            
            // Create web view
            let config = WKWebViewConfiguration()
            config.suppressesIncrementalRendering = false
            
            let webView = WKWebView(frame: CGRect(origin: .zero, size: size), configuration: config)
            webView.navigationDelegate = self
            self.webView = webView
            
            // Load HTML
            webView.loadHTMLString(html, baseURL: nil)
            
            // Setup timeout
            Task {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                if self.continuation != nil {
                    self.cleanup()
                    continuation.resume(throwing: RenderError.timeout)
                }
            }
        }
    }
    
    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            // Give WebView time to render (important for complex SVGs)
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            guard let webView = self.webView, let _ = self.continuation else {
                return
            }
            
            // Take snapshot
            let config = WKSnapshotConfiguration()
            config.rect = webView.frame
            
            webView.takeSnapshot(with: config) { image, error in
                Task { @MainActor in
                    if let error = error {
                        print("[SVGWebViewController] ❌ Snapshot failed: \(error)")
                        self.continuation?.resume(throwing: error)
                    } else if let image = image {
                        self.continuation?.resume(returning: image)
                    } else {
                        self.continuation?.resume(throwing: RenderError.snapshotFailed)
                    }
                    self.cleanup()
                }
            }
        }
    }
    
    nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            print("[SVGWebViewController] ❌ WebView failed: \(error)")
            self.continuation?.resume(throwing: RenderError.webViewLoadFailed)
            self.cleanup()
        }
    }
    
    private func cleanup() {
        self.webView?.navigationDelegate = nil
        self.webView = nil
        self.continuation = nil
    }
}


