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
                } catch {
                    log("⚠️ Failed to download chart image: \(error.localizedDescription)")
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
                // Don't throw - chart generation succeeded even if caching failed
            }

            return natalChart
        } catch {
            log("❌ Chart generation failed: \(error.localizedDescription)")
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
}
