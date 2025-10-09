//
//  ChartVisualization.swift
//  AstroSvitla
//
//  Metadata for cached chart wheel images
//

import Foundation

struct ChartVisualization: Codable, Identifiable, Sendable {
    let id: UUID
    let chartID: UUID             // References NatalChart.id
    let imageFormat: ImageFormat
    let imageURL: URL?            // S3 URL from API response
    let localFileID: String?      // Filename in local cache
    let size: Int                 // Image dimensions (pixels)
    let generatedAt: Date

    enum ImageFormat: String, Codable, Sendable {
        case svg
        case png
    }

    init(
        id: UUID = UUID(),
        chartID: UUID,
        imageFormat: ImageFormat,
        imageURL: URL? = nil,
        localFileID: String? = nil,
        size: Int = 600,
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.chartID = chartID
        self.imageFormat = imageFormat
        self.imageURL = imageURL
        self.localFileID = localFileID
        self.size = size
        self.generatedAt = generatedAt
    }
}
