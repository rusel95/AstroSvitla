import SwiftUI
import WebKit

struct SVGImageView: UIViewRepresentable {
    let svgData: Data

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.backgroundColor = .clear
        webView.navigationDelegate = context.coordinator
        webView.contentMode = .scaleAspectFit
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard context.coordinator.lastRenderedData != svgData else { return }
        context.coordinator.lastRenderedData = svgData

        print("[SVGImageView] Rendering SVG (\(svgData.count) bytes)")
        if let svgString = String(data: svgData, encoding: .utf8) {
            let html = Self.htmlTemplate(for: svgString)
            uiView.loadHTMLString(html, baseURL: nil)
        } else {
            let base64 = svgData.base64EncodedString()
            let html = Self.htmlTemplate(for: "<img src=\"data:image/svg+xml;base64,\(base64)\" style=\"width:100%;height:100%;\" />")
            uiView.loadHTMLString(html, baseURL: nil)
        }
    }
}

extension SVGImageView {
    final class Coordinator: NSObject, WKNavigationDelegate {
        var lastRenderedData: Data?

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.body.style.background = 'transparent';", completionHandler: nil)
            print("[SVGImageView] Finished rendering SVG")
        }
    }

    private static func htmlTemplate(for svgMarkup: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0">
            <style>
                html, body {
                    margin: 0;
                    padding: 0;
                    background: transparent;
                    overflow: hidden;
                }
                svg {
                    width: 100%;
                    height: 100%;
                }
            </style>
        </head>
        <body>
            \(svgMarkup)
        </body>
        </html>
        """
    }
}
