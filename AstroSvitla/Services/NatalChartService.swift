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
import Network
import Sentry

/// Protocol for natal chart generation service
protocol NatalChartServiceProtocol {
    func generateChart(birthDetails: BirthDetails, forceRefresh: Bool) async throws -> NatalChart
    func getCachedChart(birthDetails: BirthDetails) -> NatalChart?
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

            // Download SVG chart visualization
            if let imageFileID = natalChart.imageFileID, let imageFormat = natalChart.imageFormat {
                do {
                    log("🖼️ Downloading chart SVG visualization...")
                    let svgString = try await astrologyAPIService.generateChartSVG(birthDetails: birthDetails)
                    let svgData = Data(svgString.utf8)

                    // Save SVG to file system
                    let imageCacheService = ImageCacheService()
                    try imageCacheService.saveImage(data: svgData, fileID: imageFileID, format: imageFormat)
                    log("✅ Chart image saved (\(svgData.count) bytes)")

                    // Also render and save PNG version for PDF export
                    await savePNGVersionForPDF(svgString: svgString, imageFileID: imageFileID, imageCacheService: imageCacheService)
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

    // MARK: - PNG Generation for PDF Export

    /// Saves a PNG version of the chart for use in PDF export
    /// This is needed because ImageRenderer can't handle async SVG rendering
    @MainActor
    private func savePNGVersionForPDF(svgString: String, imageFileID: String, imageCacheService: ImageCacheService) async {
        do {
            let pngImage = try await renderSVGToPNG(svg: svgString, size: CGSize(width: 800, height: 800))
            if let pngData = pngImage.pngData() {
                try imageCacheService.saveImage(data: pngData, fileID: imageFileID, format: "png")
                log("📷 PNG version saved for PDF export (\(pngData.count) bytes)")
            }
        } catch {
            log("⚠️ Failed to save PNG version: \(error.localizedDescription)")
            // Non-critical - PDF will show fallback chart info
        }
    }

    /// Render SVG to PNG using WKWebView
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

            // Create a coordinator to handle navigation delegate
            let coordinator = SVGRenderCoordinator(continuation: continuation, webView: webView)
            webView.navigationDelegate = coordinator

            // Keep a strong reference to coordinator
            objc_setAssociatedObject(webView, "coordinator", coordinator, .OBJC_ASSOCIATION_RETAIN)

            webView.loadHTMLString(html, baseURL: nil)

            // Timeout after 10 seconds
            Task {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                if !coordinator.didComplete {
                    coordinator.didComplete = true
                    continuation.resume(throwing: ServiceError.chartGenerationFailed(
                        NSError(domain: "NatalChartService", code: -1, userInfo: [NSLocalizedDescriptionKey: "SVG render timeout"])
                    ))
                }
            }
        }
    }
}

// MARK: - SVG Render Coordinator

import WebKit

private class SVGRenderCoordinator: NSObject, WKNavigationDelegate {
    var continuation: CheckedContinuation<UIImage, Error>?
    var webView: WKWebView
    var didComplete = false

    init(continuation: CheckedContinuation<UIImage, Error>, webView: WKWebView) {
        self.continuation = continuation
        self.webView = webView
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard !didComplete else { return }

        // Delay to allow rendering
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self, !self.didComplete else { return }
            self.didComplete = true

            let config = WKSnapshotConfiguration()
            config.rect = webView.frame

            webView.takeSnapshot(with: config) { [weak self] image, error in
                guard let continuation = self?.continuation else { return }

                if let error = error {
                    continuation.resume(throwing: error)
                } else if let image = image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: NSError(domain: "NatalChartService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Snapshot failed"]))
                }
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard !didComplete else { return }
        didComplete = true
        continuation?.resume(throwing: error)
    }
}
