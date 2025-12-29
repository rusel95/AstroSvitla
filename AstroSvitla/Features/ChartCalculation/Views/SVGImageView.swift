import SwiftUI
import WebKit

/// Renders SVG data using WKWebView
struct SVGImageView: View {
    let svgData: Data
    
    var body: some View {
        SVGWebView(svgData: svgData)
            .aspectRatio(SVGWebView.aspectRatio, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .background(Color.white)
    }
}
