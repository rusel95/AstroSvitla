//
//  NatalChartService.swift
//  AstroSvitla
//
//  Orchestrator service for natal chart generation
//  Coordinates API calls, data mapping, caching, and offline support
//
//  API MIGRATION NOTE (2025-10-11):
//  This service has been migrated to use api.astrology-api.io as the primary API provider.
//  Previous Free Astrology API integration has been commented out but preserved for potential rollback.
//  To restore old API: uncomment FreeAstrologyAPI code and comment out AstrologyAPI code.
//

import Foundation
import SwiftData
import Sentry
import WebKit

/// Protocol for natal chart generation service
protocol NatalChartServiceProtocol {
    func generateChart(birthDetails: BirthDetails, forceRefresh: Bool) async throws -> NatalChart
    func getCachedChart(birthDetails: BirthDetails) -> NatalChart?
    func ensureChartImage(for chart: NatalChart) async -> UIImage?
}

/// Main service for generating and managing natal charts
final class NatalChartService: NatalChartServiceProtocol {

    // MARK: - Dependencies

    // NEW: Primary API service using api.astrology-api.io
    private let astrologyAPIService: AstrologyAPIService
    private let chartCacheService: ChartCacheService

    // MARK: - Errors

    enum ServiceError: LocalizedError {
        case noInternetConnection
        case rateLimitExceeded(retryAfter: TimeInterval)
        case chartGenerationFailed(Error)
        case imageDownloadFailed(Error)
        case cachingFailed(Error)
        case noCachedDataAvailable

        var errorDescription: String? {
            switch self {
            case .noInternetConnection:
                return "Unable to connect. Please check your internet connection."
            case .rateLimitExceeded(let seconds):
                return "Request limit reached. Please wait \(Int(seconds)) seconds before trying again."
            case .chartGenerationFailed(let error):
                return "Failed to generate chart: \(error.localizedDescription)"
            case .imageDownloadFailed:
                return "Chart generated successfully, but chart image could not be downloaded."
            case .cachingFailed:
                return "Chart generated successfully, but could not be saved for offline access."
            case .noCachedDataAvailable:
                return "No cached chart available. Internet connection required to generate charts."
            }
        }
    }

    // MARK: - Initialization

    init(
        astrologyAPIService: AstrologyAPIService,
        chartCacheService: ChartCacheService
    ) {
        self.astrologyAPIService = astrologyAPIService
        self.chartCacheService = chartCacheService
    }

    /// Convenience initializer with default dependencies
    convenience init(modelContext: ModelContext) {
        let astrologyAPIService = AstrologyAPIService(
            baseURL: Config.astrologyAPIBaseURL
        )
        let chartCacheService = ChartCacheService(context: modelContext)

        self.init(
            astrologyAPIService: astrologyAPIService,
            chartCacheService: chartCacheService
        )
    }

    // MARK: - Public Methods

    /// Generate natal chart with caching and offline support
    /// - Parameters:
    ///   - birthDetails: Birth information for chart calculation
    ///   - forceRefresh: If true, bypass cache and fetch fresh data from API
    /// - Returns: Complete natal chart with visualization
    /// - Throws: ServiceError if generation fails
    func generateChart(
        birthDetails: BirthDetails,
        forceRefresh: Bool = false
    ) async throws -> NatalChart {

        log("🌌 Generate chart started for \(birthDetails.displayName) (\(birthDetails.formattedBirthDate) \(birthDetails.formattedBirthTime)) forceRefresh=\(forceRefresh)")
        
        // Check cache first if not forcing refresh
        if !forceRefresh, let cachedChart = getCachedChart(birthDetails: birthDetails) {
            log("✅ Returning cached chart")
            return cachedChart
        }
        
        do {
            // Single API call to api.astrology-api.io for complete natal chart
            log("📡 Fetching natal chart from AstrologyAPI...")
            let natalChart = try await astrologyAPIService.generateNatalChart(birthDetails: birthDetails)
            log("✅ Natal chart received with \(natalChart.planets.count) planets, \(natalChart.houses.count) houses")

            // Download and save SVG, then render to PNG for PDF export
            if let imageFileID = natalChart.imageFileID {
                do {
                    log("🖼️ Downloading chart SVG visualization...")
                    let svgString = try await astrologyAPIService.generateChartSVG(birthDetails: birthDetails)

                    // Save SVG to file system
                    let imageCacheService = ImageCacheService()
                    if let svgData = svgString.data(using: .utf8) {
                        try imageCacheService.saveImage(data: svgData, fileID: imageFileID, format: "svg")
                        log("📄 SVG saved (\(svgData.count) bytes)")
                        
                        // Also render and save PNG for PDF export
                        await savePNGFromSVG(svgData: svgData, imageFileID: imageFileID, imageCacheService: imageCacheService)
                    }
                } catch {
                    log("⚠️ Failed to download chart image: \(error.localizedDescription)")

                    // Log to Sentry for image download failures - use capture(error:) for better stack traces
                    SentrySDK.capture(error: error) { scope in
                        scope.setLevel(.warning)
                        scope.setTag(value: "chart_generation", key: "service")
                        scope.setTag(value: "image_download", key: "operation")
                        scope.setContext(value: [
                            "message": "Unexpected: Chart image download failed",
                            "file_id": imageFileID
                        ], key: "error_context")
                    }
                    // Don't throw - chart data is still valid even without image
                }
            }

            // Cache the result
            do {
                try chartCacheService.saveChart(
                    natalChart,
                    birthDetails: birthDetails,
                    imageFileID: natalChart.imageFileID,
                    imageFormat: natalChart.imageFormat
                )
                log("💾 Chart cached successfully")
            } catch {
                log("⚠️ Failed to cache chart: \(error.localizedDescription)")

                // Log to Sentry for caching failures - use capture(error:) for better stack traces
                SentrySDK.capture(error: error) { scope in
                    scope.setLevel(.warning)
                    scope.setTag(value: "chart_generation", key: "service")
                    scope.setTag(value: "chart_cache", key: "operation")
                    scope.setContext(value: [
                        "message": "Unexpected: Chart caching failed"
                    ], key: "error_context")
                }
                // Don't throw - chart generation succeeded even if caching failed
            }

            return natalChart
        } catch {
            log("❌ Chart generation failed: \(error.localizedDescription)")

            // Log to Sentry for unexpected errors - use capture(error:) for better stack traces
            SentrySDK.capture(error: error) { scope in
                scope.setLevel(.error)
                scope.setTag(value: "chart_generation", key: "service")
                scope.setTag(value: "astrology_api", key: "provider")
                scope.setContext(value: [
                    "message": "Unexpected: Natal chart generation failed",
                    "birth_subject": birthDetails.displayName,
                    "birth_date": birthDetails.formattedBirthDate
                ], key: "error_context")
            }

            throw ServiceError.chartGenerationFailed(error)
        }
    }

    /// Get cached chart for given birth details
    /// - Parameter birthDetails: Birth information to search for
    /// - Returns: Cached natal chart if found, nil otherwise
    func getCachedChart(birthDetails: BirthDetails) -> NatalChart? {
        return try? chartCacheService.findChart(birthData: birthDetails)
    }

    /// Get cached chart by ID
    /// - Parameter id: Chart unique identifier
    /// - Returns: Natal chart if found, nil otherwise
    func getChart(id: UUID) -> NatalChart? {
        return try? chartCacheService.loadChart(id: id)
    }

    /// Clear old charts to free up storage
    /// - Throws: Error if cleanup fails
    func clearOldCharts() throws {
        try chartCacheService.clearOldCharts()
    }

    private func log(_ message: String) {
        print("[NatalChartService] \(message)")
    }

    /// Validates that an image contains actual chart content (not just blank white)
    /// by sampling pixels from different regions and checking for color variance
    private func isValidChartImage(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else { return false }

        let width = cgImage.width
        let height = cgImage.height

        // Need reasonable size
        guard width > 100 && height > 100 else { return false }

        // Create a small bitmap context to sample pixels
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var pixelData = [UInt8](repeating: 0, count: bytesPerRow * height)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return false }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Sample pixels from center region where chart content should be
        let centerX = width / 2
        let centerY = height / 2
        let sampleRadius = min(width, height) / 4

        var nonWhitePixels = 0
        let samplePoints = 100

        for _ in 0..<samplePoints {
            let offsetX = Int.random(in: -sampleRadius..<sampleRadius)
            let offsetY = Int.random(in: -sampleRadius..<sampleRadius)
            let x = centerX + offsetX
            let y = centerY + offsetY

            guard x >= 0 && x < width && y >= 0 && y < height else { continue }

            let offset = (y * bytesPerRow) + (x * bytesPerPixel)
            let r = pixelData[offset]
            let g = pixelData[offset + 1]
            let b = pixelData[offset + 2]

            // Check if pixel is not white/near-white (allowing for some tolerance)
            if r < 240 || g < 240 || b < 240 {
                nonWhitePixels += 1
            }
        }

        // A valid chart should have at least 10% non-white pixels in the center region
        let isValid = nonWhitePixels > samplePoints / 10
        log("📊 Image validation: \(nonWhitePixels)/\(samplePoints) non-white pixels → \(isValid ? "valid" : "invalid")")
        return isValid
    }
    
    // MARK: - Public Image Access

    /// Ensures a PNG image of the chart is available (generates from SVG if needed)
    /// Used for PDF export and Instagram sharing
    func ensureChartImage(for chart: NatalChart) async -> UIImage? {
        guard let imageFileID = chart.imageFileID else { return nil }
        let imageCacheService = ImageCacheService()

        // 1. Try to load existing PNG
        if imageCacheService.imageExists(fileID: imageFileID, format: "png") {
            if let data = try? imageCacheService.loadImage(fileID: imageFileID, format: "png"),
               let image = UIImage(data: data) {
                // Validate the image has actual content by checking pixel data
                // A blank white image will have very low variance in pixel values
                if isValidChartImage(image) {
                    log("✅ Loaded valid cached PNG (\(data.count) bytes)")
                    return image
                } else {
                    log("⚠️ Cached PNG appears to be blank or invalid. Forcing regeneration.")
                    try? imageCacheService.deleteImage(fileID: imageFileID, format: "png")
                }
            }
        }

        // 2. If no PNG, try to render from SVG
        if imageCacheService.imageExists(fileID: imageFileID, format: "svg") {
            do {
                if let svgData = try? imageCacheService.loadImage(fileID: imageFileID, format: "svg") {
                    await savePNGFromSVG(svgData: svgData, imageFileID: imageFileID, imageCacheService: imageCacheService)
                    
                    // 3. Load the newly generated PNG
                    if let data = try? imageCacheService.loadImage(fileID: imageFileID, format: "png"),
                       let image = UIImage(data: data) {
                        return image
                    }
                }
            }
        }

        return nil
    }

    // MARK: - PNG Generation from SVG

    /// Render SVG to PNG using WKWebView and save to cache
    /// Uses approach from main branch which doesn't require a window
    @MainActor
    private func savePNGFromSVG(svgData: Data, imageFileID: String, imageCacheService: ImageCacheService) async {
        guard let svgString = String(data: svgData, encoding: .utf8) else {
            log("⚠️ Failed to convert SVG data to string")
            return
        }

        let chartWidth: CGFloat = 820
        let chartHeight: CGFloat = 550
        let size = CGSize(width: chartWidth, height: chartHeight)

        log("🎨 Rendering SVG to PNG...")

        do {
            let pngImage = try await renderSVGToPNG(svg: svgString, size: size)
            if let pngData = pngImage.pngData() {
                try imageCacheService.saveImage(data: pngData, fileID: imageFileID, format: "png")
                log("📷 PNG saved (\(pngData.count) bytes)")
            }
        } catch {
            log("⚠️ Failed to render SVG to PNG: \(error.localizedDescription)")
        }
    }

    /// Render SVG to PNG using WKWebView (approach from main branch)
    @MainActor
    private func renderSVGToPNG(svg: String, size: CGSize) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let html = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <style>
                    * { margin: 0; padding: 0; }
                    html, body {
                        width: \(Int(size.width))px;
                        height: \(Int(size.height))px;
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

            let config = WKWebViewConfiguration()
            let webView = WKWebView(frame: CGRect(origin: .zero, size: size), configuration: config)

            let coordinator = SVGRenderCoordinator(continuation: continuation, webView: webView)
            webView.navigationDelegate = coordinator

            // Keep a strong reference to coordinator
            objc_setAssociatedObject(webView, "coordinator", coordinator, .OBJC_ASSOCIATION_RETAIN)

            webView.loadHTMLString(html, baseURL: nil)

            // Timeout after 10 seconds
            Task {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                coordinator.timeout()
            }
        }
    }
}

// MARK: - SVG Render Coordinator

private class SVGRenderCoordinator: NSObject, WKNavigationDelegate {
    private var continuation: CheckedContinuation<UIImage, Error>?
    private var webView: WKWebView
    private(set) var didComplete = false
    private let lock = NSLock()

    init(continuation: CheckedContinuation<UIImage, Error>, webView: WKWebView) {
        self.continuation = continuation
        self.webView = webView
    }

    private func complete(with result: Result<UIImage, Error>) {
        lock.lock()
        defer { lock.unlock() }

        guard !didComplete, let continuation = continuation else { return }
        didComplete = true
        self.continuation = nil

        switch result {
        case .success(let image):
            continuation.resume(returning: image)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard !didComplete else { return }

        print("[NatalChartService] ✅ WebView finished loading, waiting for render...")

        // Delay to allow rendering (0.5s as in main branch)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self, !self.didComplete else { return }

            let config = WKSnapshotConfiguration()
            config.rect = webView.frame

            webView.takeSnapshot(with: config) { [weak self] image, error in
                if let error = error {
                    print("[NatalChartService] ❌ Snapshot error: \(error)")
                    self?.complete(with: .failure(error))
                } else if let image = image {
                    print("[NatalChartService] 📷 Snapshot taken: \(image.size)")
                    self?.complete(with: .success(image))
                } else {
                    print("[NatalChartService] ❌ Snapshot returned nil")
                    self?.complete(with: .failure(NSError(domain: "NatalChartService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Snapshot failed"])))
                }
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("[NatalChartService] ❌ WebView navigation failed: \(error)")
        complete(with: .failure(error))
    }

    func timeout() {
        print("[NatalChartService] ⏰ Timeout waiting for PNG render")
        complete(with: .failure(NSError(domain: "NatalChartService", code: -1, userInfo: [NSLocalizedDescriptionKey: "SVG render timeout"])))
    }
}
