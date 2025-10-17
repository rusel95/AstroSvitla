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
        let cached = try fetchCachedChart(for: birthDetails) ?? CachedNatalChart()
        let isNew = cached.persistentModelID == nil
        
        try cached.apply(
            chart: chart,
            birthDetails: birthDetails,
            houseSystem: defaultHouseSystem,
            imageFileID: imageFileID,
            imageFormat: imageFormat
        )

        if isNew {
            context.insert(cached)
        }

        try context.save()
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
        guard let cached = try fetchCachedChart(for: birthData) else {
            return nil
        }

        return try cached.toNatalChart()
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
        let descriptor = FetchDescriptor<CachedNatalChart>()
        return try context.fetch(descriptor)
            .first(where: { $0.matches(birthDetails) })
    }
}
