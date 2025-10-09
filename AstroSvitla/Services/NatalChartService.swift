//
//  NatalChartService.swift
//  AstroSvitla
//
//  Orchestrates natal chart generation via Prokerala API
//  Coordinates API calls, mapping, and caching
//

import Foundation

final class NatalChartService {

    private let apiService: ProkralaAPIServiceProtocol

    init(apiService: ProkralaAPIServiceProtocol) {
        self.apiService = apiService
    }

    /// Convenience initializer with default API service
    convenience init() {
        // Note: This will fail if Config.swift doesn't have real credentials
        // Users must create Config.swift from Config.swift.example
        let apiService = ProkralaAPIService(
            userID: Config.astrologyAPIUserID,
            apiKey: Config.astrologyAPIKey
        )
        self.init(apiService: apiService)
    }

    // MARK: - Public API

    /// Generate natal chart from birth details
    /// - Parameter birthDetails: User's birth information
    /// - Returns: Tuple of (planets, houses, aspects) and optional image URL
    /// - Throws: APIError if generation fails
    func generateChart(
        birthDetails: BirthDetails
    ) async throws -> (planets: [Planet], houses: [House], aspects: [Aspect], imageURL: String?) {

        let request = NatalChartRequest(birthDetails: birthDetails)

        // Make parallel API calls for data and image
        async let chartDataTask = apiService.fetchChartData(request)
        async let chartImageTask = apiService.generateChartImage(request)

        // Await both results
        let (chartData, chartImage) = try await (chartDataTask, chartImageTask)

        // Map DTOs to domain models
        let (planets, houses, aspects) = try DTOMapper.toDomain(
            response: chartData,
            birthDetails: birthDetails
        )

        // Extract image URL
        let imageURL = chartImage.status ? chartImage.chart_url : nil

        return (planets, houses, aspects, imageURL)
    }
}
