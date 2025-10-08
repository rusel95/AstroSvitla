import Foundation
import Combine
import SwiftData

@MainActor
final class ReportListViewModel: ObservableObject {

    struct Section: Identifiable {
        let id: UUID
        let chartName: String
        let chartSubtitle: String
        let reports: [Item]

        var isOrphan: Bool
    }

    struct Item: Identifiable {
        let id: UUID
        let report: ReportPurchase
        let areaDisplayName: String
        let areaIconName: String
        let purchaseDateText: String
        let readingTimeText: String
        let languageDisplay: String
    }

    @Published private(set) var sections: [Section] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private var modelContext: ModelContext?
    private var didConfigure = false

    func configureIfNeeded(with context: ModelContext) {
        guard didConfigure == false else { return }
        modelContext = context
        didConfigure = true
        loadReports()
    }

    func refresh() {
        loadReports()
    }

    private func loadReports() {
        guard let context = modelContext else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let descriptor = FetchDescriptor<ReportPurchase>(
                sortBy: [SortDescriptor(\.purchaseDate, order: .reverse)]
            )
            let reports = try context.fetch(descriptor)
            sections = Self.buildSections(from: reports)
            errorMessage = nil
        } catch {
            errorMessage = "Не вдалося завантажити збережені звіти."
            sections = []
        }
    }
}

// MARK: - Builders

private extension ReportListViewModel {

    static func buildSections(from reports: [ReportPurchase]) -> [Section] {
        guard reports.isEmpty == false else { return [] }

        let grouped = Dictionary(grouping: reports) { purchase -> UUID in
            if let chartId = purchase.chart?.id {
                return chartId
            } else {
                return .orphanChartGroupingKey
            }
        }

        let sections: [Section] = grouped.map { grouping in
            let chartId = grouping.key
            let purchases = grouping.value.sorted(by: { $0.purchaseDate > $1.purchaseDate })

            let chart = purchases.first?.chart
            let isOrphan = chart == nil
            let chartName = chart.flatMap { $0.name.isEmpty ? nil : $0.name } ?? "Невідомий профіль"
            let subtitle = chart.map { chartSubtitle(for: $0) } ?? "Без прив'язки до карти"

            let items = purchases.map { purchase in
                makeItem(from: purchase)
            }

            return Section(
                id: chart?.id ?? chartId,
                chartName: chartName,
                chartSubtitle: subtitle,
                reports: items,
                isOrphan: isOrphan
            )
        }

        return sections.sorted { lhs, rhs in
            guard let lhsDate = lhs.reports.first?.report.purchaseDate,
                  let rhsDate = rhs.reports.first?.report.purchaseDate else {
                return lhs.chartName < rhs.chartName
            }
            return lhsDate > rhsDate
        }
    }

    static func makeItem(from report: ReportPurchase) -> Item {
        let area = ReportArea(rawValue: report.area)
        let displayName = area?.displayName ?? report.areaDisplayName
        let iconName = area?.icon ?? "doc.text"
        let purchaseText = purchaseDateFormatter.string(from: report.purchaseDate)
        let readingTime = "≈\(report.estimatedReadingTime) хв"
        let languageName = Locale.current.localizedString(forLanguageCode: report.language) ?? report.language.uppercased()

        return Item(
            id: report.id,
            report: report,
            areaDisplayName: displayName,
            areaIconName: iconName,
            purchaseDateText: purchaseText,
            readingTimeText: readingTime,
            languageDisplay: languageName
        )
    }

    static func chartSubtitle(for chart: BirthChart) -> String {
        let location = chart.locationName.isEmpty ? nil : chart.locationName
        let birthDate = Self.birthDateFormatter.string(from: chart.birthDate)
        let birthTime = Self.birthTimeFormatter.string(from: chart.birthTime)

        if let location {
            return "\(birthDate) • \(birthTime) • \(location)"
        } else {
            return "\(birthDate) • \(birthTime)"
        }
    }
}

// MARK: - Formatters & Helpers

private extension ReportListViewModel {
    static let purchaseDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static let birthDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    static let birthTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

private extension UUID {
    static let orphanChartGroupingKey = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
}
