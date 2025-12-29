import SwiftUI
import Foundation
import SwiftData

struct NatalChartWheelView: View {
    let chart: NatalChart
    var allowsZoom: Bool = false
    var zoomScale: CGFloat = 1.0
    var zoomScaleX: CGFloat? = nil
    var zoomScaleY: CGFloat? = nil
    var zoomAnchor: UnitPoint = .center
    var showsShareButton: Bool = false
    @Environment(\.modelContext) private var modelContext

    @State private var svgData: Data?
    @State private var imageLoadingFailed = false
    @State private var isLoadingImage = false
    @State private var showFullScreenChart = false
    @State private var isPresentingShareSheet = false

    var body: some View {
        Group {
            if let svgData = svgData {
                chartSVGView(svgData: svgData)
            } else if imageLoadingFailed {
                errorPlaceholder
            } else {
                // Loading placeholder with same aspect ratio as chart
                ProgressView("chart.loading")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // Fixed aspect ratio to prevent height jumping during loading
        .aspectRatio(SVGWebView.aspectRatio, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .task {
            await loadChartSVG()
            if showsShareButton {
                await loadShareImage()
            }
        }
        .sheet(isPresented: $isPresentingShareSheet) {
            if let shareImage {
                ShareSheet(activityItems: [shareImage])
            }
        }
        .fullScreenCover(isPresented: $showFullScreenChart) {
            if let svgData = svgData {
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    SVGWebView(svgData: svgData)
                        .aspectRatio(SVGWebView.aspectRatio, contentMode: .fit)
                }
                .onTapGesture {
                    showFullScreenChart = false
                }
                .overlay(alignment: .topTrailing) {
                    Button {
                        showFullScreenChart = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .padding()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func chartSVGView(svgData: Data) -> some View {
        let scaleX = zoomScaleX ?? zoomScale
        let scaleY = zoomScaleY ?? zoomScale

        if allowsZoom {
            SVGWebView(svgData: svgData)
                .aspectRatio(SVGWebView.aspectRatio, contentMode: .fit)
                .scaleEffect(x: scaleX, y: scaleY, anchor: zoomAnchor)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .onTapGesture {
                    showFullScreenChart = true
                }
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                        .padding(8)
                }
                .overlay(alignment: .topTrailing) {
                    if showsShareButton {
                        shareButton
                    }
                }
        } else {
            SVGWebView(svgData: svgData)
                .aspectRatio(SVGWebView.aspectRatio, contentMode: .fit)
                .scaleEffect(x: scaleX, y: scaleY, anchor: zoomAnchor)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    if showsShareButton {
                        shareButton
                    }
                }
        }
    }

    @ViewBuilder
    private var errorPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.pie")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("chart.unavailable")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var shareButton: some View {
        Button {
            isPresentingShareSheet = true
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .padding(8)
                .background(Color.black.opacity(0.5))
                .clipShape(Circle())
        }
        .padding(8)
    }

    @State private var shareImage: UIImage?

    /// Load PNG image for sharing (generated from SVG)
    private func loadShareImage() async {
        guard chart.imageFileID != nil else { return }

        let service = NatalChartService(modelContext: modelContext)
        if let image = await service.ensureChartImage(for: chart) {
            await MainActor.run {
                self.shareImage = image
            }
            print("[NatalChartWheelView] ✅ Share image loaded: \(image.size)")
        } else {
            print("[NatalChartWheelView] ⚠️ No share image available")
        }
    }

    // MARK: - SVG Loading

    private func loadChartSVG() async {
        guard let imageFileID = chart.imageFileID else {
            await MainActor.run {
                self.imageLoadingFailed = true
                self.isLoadingImage = false
            }
            print("[NatalChartWheelView] No image metadata")
            return
        }

        await MainActor.run {
            isLoadingImage = true
            imageLoadingFailed = false
        }

        let imageCacheService = ImageCacheService()

        if imageCacheService.imageExists(fileID: imageFileID, format: "svg") {
            do {
                let svgData = try imageCacheService.loadImage(fileID: imageFileID, format: "svg")
                await MainActor.run {
                    self.svgData = svgData
                    self.isLoadingImage = false
                }
                print("[NatalChartWheelView] ✅ SVG loaded (\(svgData.count) bytes)")
                return
            } catch {
                print("[NatalChartWheelView] ❌ Failed to load SVG: \(error)")
            }
        } else {
            print("[NatalChartWheelView] ❌ No cached SVG found for id=\(imageFileID)")
        }

        await MainActor.run {
            self.imageLoadingFailed = true
            self.isLoadingImage = false
        }
    }
}
