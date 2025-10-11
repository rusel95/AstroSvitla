import SwiftUI
import UIKit
import WebKit

struct SVGImageView: View {
    let svgData: Data

    @State private var renderedImage: UIImage?
    @State private var isRendering = false

    var body: some View {
        GeometryReader { geometry in
            Group {
                if let image = renderedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if isRendering {
                    ProgressView("Rendering chart...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Color.clear
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .onChange(of: geometry.size) { oldSize, newSize in
                if newSize.width > 0 && newSize.height > 0 && renderedImage == nil {
                    renderSVG(size: newSize)
                }
            }
            .onAppear {
                if geometry.size.width > 0 && geometry.size.height > 0 {
                    renderSVG(size: geometry.size)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func renderSVG(size: CGSize) {
        guard !isRendering else { return }
        isRendering = true

        print("[SVGImageView] Starting SVG render for size: \(size)")

        Task { @MainActor in
            let image = await SVGRenderer.render(svgData: svgData, targetSize: size)
            self.renderedImage = image
            self.isRendering = false

            if image != nil {
                print("[SVGImageView] ✅ SVG rendered successfully")
            } else {
                print("[SVGImageView] ❌ Failed to render SVG")
            }
        }
    }
}

// MARK: - SVG Renderer

actor SVGRenderer {
    static func render(svgData: Data, targetSize: CGSize) async -> UIImage? {
        guard targetSize.width > 0, targetSize.height > 0 else { return nil }

        guard let svgString = String(data: svgData, encoding: .utf8) else {
            print("[SVGRenderer] Failed to decode SVG data")
            return nil
        }

        // Extract SVG dimensions
        let svgSize = extractSVGDimensions(from: svgString)

        // Calculate scale to fit
        let scale = min(targetSize.width / svgSize.width, targetSize.height / svgSize.height)
        let scaledSize = CGSize(
            width: svgSize.width * scale,
            height: svgSize.height * scale
        )

        print("[SVGRenderer] SVG: \(svgSize) -> scaled: \(scaledSize)")

        // Render using WebKit snapshot
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let image = renderWithWebKit(svgString: svgString, size: scaledSize)
                continuation.resume(returning: image)
            }
        }
    }

    private static func extractSVGDimensions(from svgString: String) -> CGSize {
        var width: CGFloat = 700
        var height: CGFloat = 700

        // Extract width
        if let match = svgString.range(of: "width=\"([0-9.]+)\"", options: .regularExpression) {
            let value = svgString[match]
                .replacingOccurrences(of: "width=\"", with: "")
                .replacingOccurrences(of: "\"", with: "")
            width = CGFloat(Double(value) ?? 700)
        }

        // Extract height
        if let match = svgString.range(of: "height=\"([0-9.]+)\"", options: .regularExpression) {
            let value = svgString[match]
                .replacingOccurrences(of: "height=\"", with: "")
                .replacingOccurrences(of: "\"", with: "")
            height = CGFloat(Double(value) ?? 700)
        }

        return CGSize(width: width, height: height)
    }

    private static func renderWithWebKit(svgString: String, size: CGSize) -> UIImage? {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=\(Int(size.width)), initial-scale=1.0, maximum-scale=1.0">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body {
                    width: \(Int(size.width))px;
                    height: \(Int(size.height))px;
                    overflow: hidden;
                }
                body {
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    background: white;
                }
                svg {
                    max-width: 100%;
                    max-height: 100%;
                    width: auto;
                    height: auto;
                }
            </style>
        </head>
        <body>\(svgString)</body>
        </html>
        """

        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: CGRect(origin: .zero, size: size), configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .white

        let semaphore = DispatchSemaphore(value: 0)
        var snapshot: UIImage?

        webView.loadHTMLString(html, baseURL: nil)

        // Wait for rendering, then snapshot
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let snapshotConfig = WKSnapshotConfiguration()
            snapshotConfig.rect = CGRect(origin: .zero, size: size)

            webView.takeSnapshot(with: snapshotConfig) { image, error in
                if let error = error {
                    print("[SVGRenderer] Snapshot error: \(error.localizedDescription)")
                } else {
                    snapshot = image
                }
                semaphore.signal()
            }
        }

        // Wait max 3 seconds
        _ = semaphore.wait(timeout: .now() + 3.0)

        return snapshot
    }
}
