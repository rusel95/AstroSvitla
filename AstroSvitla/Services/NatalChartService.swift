//
//  NatalChartService.swift
//  AstroSvitla
//
//  Orchestrator service for natal chart generation
//  Coordinates API calls, data mapping, caching, and offline support
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

    private let apiService: ProkralaAPIServiceProtocol
    private let chartCacheService: ChartCacheService
    private let imageCacheService: ImageCacheService
    private let rateLimiter: RateLimiter
    private let networkMonitor: NetworkMonitor

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
        apiService: ProkralaAPIServiceProtocol,
        chartCacheService: ChartCacheService,
        imageCacheService: ImageCacheService,
        rateLimiter: RateLimiter,
        networkMonitor: NetworkMonitor
    ) {
        self.apiService = apiService
        self.chartCacheService = chartCacheService
        self.imageCacheService = imageCacheService
        self.rateLimiter = rateLimiter
        self.networkMonitor = networkMonitor
    }

    /// Convenience initializer with default dependencies
    convenience init(modelContext: ModelContext) {
        let apiService = ProkralaAPIService(
            clientID: Config.prokeralaClientID,
            clientSecret: Config.prokeralaClientSecret
        )
        let chartCacheService = ChartCacheService(context: modelContext)
        let imageCacheService = ImageCacheService()
        let rateLimiter = RateLimiter()
        let networkMonitor = NetworkMonitor()

        self.init(
            apiService: apiService,
            chartCacheService: chartCacheService,
            imageCacheService: imageCacheService,
            rateLimiter: rateLimiter,
            networkMonitor: networkMonitor
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

        // Step 1: Check cache first (unless force refresh requested)
        if !forceRefresh {
            if let cachedChart = getCachedChart(birthDetails: birthDetails) {
                // Cache is fresh, return it
                log("💾 Returning cached chart")
                return cachedChart
            }
        }

        // Step 2: Check network connectivity
        guard networkMonitor.isConnected else {
            // If offline, try to return cached data
            if let cachedChart = getCachedChart(birthDetails: birthDetails) {
                log("⚠️ Offline but cache available, returning cached chart")
                return cachedChart
            }
            log("❌ No internet connection and no cache available")
            throw ServiceError.noInternetConnection
        }

        // Step 3: Check rate limits
        let rateLimitCheck = rateLimiter.canMakeRequest()
        guard rateLimitCheck.allowed else {
            log("❌ Rate limit exceeded, retry after \(rateLimitCheck.retryAfter ?? 60)s")
            throw ServiceError.rateLimitExceeded(retryAfter: rateLimitCheck.retryAfter ?? 60)
        }

        // Step 4: Make API call for computational data
        let request = NatalChartRequest(birthDetails: birthDetails)
        let start = Date()

        do {
            // Record API request for rate limiting
            rateLimiter.recordRequest()

            let dataResponse = try await apiService.fetchChartData(request)
            log("✅ Chart compute response received in \(String(format: "%.2f", Date().timeIntervalSince(start)))s")

            // Step 5: Map API response to domain model
            var natalChart = try DTOMapper.toDomain(response: dataResponse, birthDetails: birthDetails)

            // Step 6: Cache natal chart for offline access (no image request)
            do {
                try chartCacheService.saveChart(
                    natalChart,
                    birthDetails: birthDetails,
                    imageFileID: natalChart.imageFileID,
                    imageFormat: natalChart.imageFormat
                )
                log("💾 Chart cached successfully")
            } catch {
                // Caching failed, but chart was generated successfully
                print("Warning: Failed to cache chart: \(error)")
                log("⚠️ Failed to cache chart: \(error.localizedDescription)")
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

    /// Get current cache statistics
    /// - Returns: Total image cache size in bytes
    func getImageCacheSize() -> Int {
        return (try? imageCacheService.cacheSize()) ?? 0
    }

    /// Check if online and can make new chart requests
    /// - Returns: True if online and within rate limits
    func canGenerateChart() -> Bool {
        guard networkMonitor.isConnected else {
            return false
        }

        return rateLimiter.canMakeRequest().allowed
    }

    /// Get time remaining until next request is allowed
    /// - Returns: Seconds to wait, or nil if request can be made now
    func getRetryAfterSeconds() -> TimeInterval? {
        let check = rateLimiter.canMakeRequest()
        return check.allowed ? nil : check.retryAfter
    }

    private func log(_ message: String) {
        print("[NatalChartService] \(message)")
    }
}

// MARK: - Image Access

extension NatalChartService {

    /// Load cached chart image data
    /// - Parameters:
    ///   - fileID: Image file identifier
    ///   - format: Image format (svg or png)
    /// - Returns: Image data
    /// - Throws: Error if image not found or cannot be loaded
    func loadChartImage(fileID: String, format: String) throws -> Data {
        return try imageCacheService.loadImage(fileID: fileID, format: format)
    }

    /// Check if chart image is cached
    /// - Parameters:
    ///   - fileID: Image file identifier
    ///   - format: Image format (svg or png)
    /// - Returns: True if image is cached locally
    func hasChartImage(fileID: String, format: String) -> Bool {
        return imageCacheService.imageExists(fileID: fileID, format: format)
    }
}
