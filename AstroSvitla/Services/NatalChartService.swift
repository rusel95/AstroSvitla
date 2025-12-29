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
    
    // MARK: - Public Image Access

    /// Ensures a PNG image of the chart is available (generates from SVG if needed)
    /// Used for PDF export and Instagram sharing
    func ensureChartImage(for chart: NatalChart) async -> UIImage? {
        guard let imageFileID = chart.imageFileID else { return nil }
        let imageCacheService = ImageCacheService()

        // 1. Try to load existing PNG
        if imageCacheService.imageExists(fileID: imageFileID, format: "png") {
            do {
                if let data = try? imageCacheService.loadImage(fileID: imageFileID, format: "png") {
                    // Validate image data size. A blank chart (just white bg) is ~70KB.
                    // A valid chart with content is typically > 100KB.
                    if data.count > 100_000, let image = UIImage(data: data) {
                        return image
                    } else {
                        log("⚠️ Cached PNG is suspiciously small (\(data.count) bytes) or invalid. Forcing regeneration.")
                        // Remove invalid/blank image
                        try? imageCacheService.deleteImage(fileID: imageFileID, format: "png")
                    }
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
        
        let image: UIImage? = await withCheckedContinuation { continuation in
            // Use same HTML template as SVGWebView which is known to work
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
            
            let config = WKWebViewConfiguration()
            config.suppressesIncrementalRendering = true // Ensure full render
            
            let webView = WKWebView(frame: CGRect(origin: .zero, size: size), configuration: config)
            webView.isOpaque = false // Match SVGWebView
            webView.backgroundColor = .white
            webView.scrollView.backgroundColor = .white
            
            // WKWebView needs to be added to a window to render properly
            let window = UIWindow(frame: CGRect(origin: .zero, size: size))
            window.rootViewController = UIViewController()
            window.rootViewController?.view.addSubview(webView)
            window.isHidden = false
            window.makeKeyAndVisible()
            
            let coordinator = SVGToPNGCoordinator(continuation: continuation, window: window)
            webView.navigationDelegate = coordinator
            
            // Keep coordinator and window alive
            objc_setAssociatedObject(webView, "coordinator", coordinator, .OBJC_ASSOCIATION_RETAIN)
            objc_setAssociatedObject(webView, "window", window, .OBJC_ASSOCIATION_RETAIN)
            
            webView.loadHTMLString(html, baseURL: nil)
            
            // Timeout after 15 seconds
            Task {
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                if !coordinator.didComplete {
                    print("[NatalChartService] ⏰ Timeout waiting for PNG render")
                    coordinator.didComplete = true
                    continuation.resume(returning: nil)
                }
            }
        }
        
        guard let image = image, let pngData = image.pngData() else {
            log("⚠️ Failed to render SVG to PNG")
            return
        }
        
        do {
            try imageCacheService.saveImage(data: pngData, fileID: imageFileID, format: "png")
            log("📷 PNG saved (\(pngData.count) bytes)")
        } catch {
            log("⚠️ Failed to save PNG: \(error.localizedDescription)")
        }
    }
}

// MARK: - SVG to PNG Coordinator

private class SVGToPNGCoordinator: NSObject, WKNavigationDelegate {
    var continuation: CheckedContinuation<UIImage?, Never>?
    var didComplete = false
    var window: UIWindow?
    
    init(continuation: CheckedContinuation<UIImage?, Never>, window: UIWindow) {
        self.continuation = continuation
        self.window = window
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard !didComplete else { return }
        
        print("[NatalChartService] ✅ WebView finished loading, waiting for render...")
        
        // Wait longer for rendering to complete/paint
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self, !self.didComplete else { return }
            self.didComplete = true
            
            let config = WKSnapshotConfiguration()
            config.rect = webView.bounds
            
            webView.takeSnapshot(with: config) { [weak self] image, error in
                if let error = error {
                    print("[NatalChartService] ❌ Snapshot error: \(error)")
                } else if let image = image {
                    print("[NatalChartService] 📷 Snapshot taken: \(image.size)")
                } else {
                    print("[NatalChartService] ❌ Snapshot returned nil")
                }
                
                // Clean up window
                self?.window?.isHidden = true
                self?.window = nil
                
                self?.continuation?.resume(returning: image)
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard !didComplete else { return }
        didComplete = true
        print("[NatalChartService] ❌ WebView navigation failed: \(error)")
        window?.isHidden = true
        window = nil
        continuation?.resume(returning: nil)
    }
}
