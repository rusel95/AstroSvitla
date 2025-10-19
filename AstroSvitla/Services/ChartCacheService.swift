//
//  ChartCacheService.swift
//  AstroSvitla
//  SwiftData-backed cache for natal charts and metadata.
import Foundation
import SwiftData

final class ChartCacheService {

    private let context: ModelContext
    private let defaultHouseSystem: String
    private let maxCacheAge: TimeInterval

    init(
        context: ModelContext,
        defaultHouseSystem: String = "placidus",
        maxCacheAge: TimeInterval = 30 * 24 * 60 * 60
    ) {
        self.context = context
        self.defaultHouseSystem = defaultHouseSystem
        self.maxCacheAge = maxCacheAge
    }

    // MARK: - Persistence

    func saveChart(
        _ chart: NatalChart,
        birthDetails: BirthDetails,
        imageFileID: String? = nil,
        imageFormat: String? = nil
    ) throws {
        print("[ChartCacheService] Saving chart for \(birthDetails.displayName)")
        print("[ChartCacheService] Image metadata: fileID=\(imageFileID ?? "nil"), format=\(imageFormat ?? "nil")")

        if let existingCached = try fetchCachedChart(for: birthDetails) {
            // Update existing cached chart
            print("[ChartCacheService] Updating existing cached chart (id: \(existingCached.id))")
            try existingCached.apply(
                chart: chart,
                birthDetails: birthDetails,
                houseSystem: defaultHouseSystem,
                imageFileID: imageFileID,
                imageFormat: imageFormat
            )
        } else {
            // Create and insert new cached chart
            print("[ChartCacheService] Creating new cached chart")
            let newCached = CachedNatalChart()
            try newCached.apply(
                chart: chart,
                birthDetails: birthDetails,
                houseSystem: defaultHouseSystem,
                imageFileID: imageFileID,
                imageFormat: imageFormat
            )
            context.insert(newCached)
            print("[ChartCacheService] Inserted new chart (id: \(newCached.id))")
        }

        try context.save()
        print("[ChartCacheService] Context saved successfully")
    }

    func loadChart(id: UUID) throws -> NatalChart? {
        let descriptor = FetchDescriptor<CachedNatalChart>(
            predicate: #Predicate { $0.id == id }
        )

        guard let cached = try context.fetch(descriptor).first else {
            return nil
        }

        return try cached.toNatalChart()
    }

    func findChart(birthData: BirthDetails) throws -> NatalChart? {
        print("[ChartCacheService] Looking for cached chart for \(birthData.displayName)")

        guard let cached = try fetchCachedChart(for: birthData) else {
            print("[ChartCacheService] No cached chart found")
            return nil
        }

        let chart = try cached.toNatalChart()
        print("[ChartCacheService] Successfully loaded cached chart with \(chart.planets.count) planets")
        return chart
    }

    func isCacheStale(_ cachedChart: CachedNatalChart, referenceDate: Date = Date()) -> Bool {
        referenceDate.timeIntervalSince(cachedChart.generatedAt) > maxCacheAge
    }

    func clearOldCharts(olderThan days: Int = 30, referenceDate: Date = Date()) throws {
        let threshold = referenceDate.addingTimeInterval(-TimeInterval(days) * 24 * 60 * 60)
        let descriptor = FetchDescriptor<CachedNatalChart>()
        let cachedCharts = try context.fetch(descriptor)

        var didDelete = false
        for chart in cachedCharts where chart.generatedAt < threshold {
            context.delete(chart)
            didDelete = true
        }

        if didDelete {
            try context.save()
        }
    }

    // MARK: - Helpers

    private func fetchCachedChart(for birthDetails: BirthDetails) throws -> CachedNatalChart? {
        // Fetch all cached charts and find matching one
        // Note: We can't use predicates on JSON fields, so we must filter in memory
        let descriptor = FetchDescriptor<CachedNatalChart>(
            sortBy: [SortDescriptor(\CachedNatalChart.generatedAt, order: .reverse)]
        )
        let allCharts = try context.fetch(descriptor)

        print("[ChartCacheService] Searching for cached chart among \(allCharts.count) cached charts")

        let match = allCharts.first(where: { $0.matches(birthDetails) })

        if let match = match {
            print("[ChartCacheService] ✅ Found cached chart (generated: \(match.generatedAt))")
        } else {
            print("[ChartCacheService] ❌ No cached chart found for \(birthDetails.displayName)")
        }

        return match
    }
}
