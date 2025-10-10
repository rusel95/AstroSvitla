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
            token: Config.prokeralaAPIToken
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

        // Step 1: Check cache first (unless force refresh requested)
        if !forceRefresh {
            if let cachedChart = getCachedChart(birthDetails: birthDetails) {
                // Cache is fresh, return it
                return cachedChart
            }
        }

        // Step 2: Check network connectivity
        guard networkMonitor.isConnected else {
            // If offline, try to return cached data
            if let cachedChart = getCachedChart(birthDetails: birthDetails) {
                return cachedChart
            }
            throw ServiceError.noInternetConnection
        }

        // Step 3: Check rate limits
        let rateLimitCheck = rateLimiter.canMakeRequest()
        guard rateLimitCheck.allowed else {
            throw ServiceError.rateLimitExceeded(retryAfter: rateLimitCheck.retryAfter ?? 60)
        }

        // Step 4: Make API calls (parallel execution for performance)
        let request = NatalChartRequest(birthDetails: birthDetails)

        do {
            // Record API requests for rate limiting (2 requests per chart)
            rateLimiter.recordRequest()
            rateLimiter.recordRequest()

            // Parallel API calls to meet < 5 second requirement
            async let chartDataResponse = apiService.fetchChartData(request)
            async let chartImageResponse = apiService.generateChartImage(request)

            let (dataResponse, imageResponse) = try await (chartDataResponse, chartImageResponse)

            // Step 5: Map API response to domain model
            var natalChart = try DTOMapper.toDomain(response: dataResponse, birthDetails: birthDetails)

            // Step 6: Download and cache chart image
            if imageResponse.status, let imageURL = URL(string: imageResponse.chart_url) {
                do {
                    let (imageData, _) = try await URLSession.shared.data(from: imageURL)
                    let fileID = UUID().uuidString
                    let format = request.imageFormat

                    try imageCacheService.saveImage(data: imageData, fileID: fileID, format: format)

                    // Update chart with image information
                    natalChart.imageFileID = fileID
                    natalChart.imageFormat = format
                } catch {
                    // Image download failed, but continue with chart data
                    // This is a non-fatal error - user can still see chart data
                    print("Warning: Failed to download chart image: \(error)")
                }
            }

            // Step 7: Cache natal chart for offline access
            do {
                try chartCacheService.saveChart(
                    natalChart,
                    birthDetails: birthDetails,
                    imageFileID: natalChart.imageFileID,
                    imageFormat: natalChart.imageFormat
                )
            } catch {
                // Caching failed, but chart was generated successfully
                print("Warning: Failed to cache chart: \(error)")
            }

            return natalChart

        } catch {
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
