import SwiftUI
import CoreLocation
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var onboardingViewModel: OnboardingViewModel
    @State private var flowState: FlowState
    @State private var isShowingReportList = false
    @State private var errorMessage: String?

    private let chartCalculator = ChartCalculator()
    private let reportGenerator = AIReportGenerator()

    init() {
        let onboardingViewModel = OnboardingViewModel()
        _onboardingViewModel = StateObject(wrappedValue: onboardingViewModel)
        let initialFlow: FlowState = onboardingViewModel.isCompleted ? .birthInput(existing: nil) : .onboarding
        _flowState = State(initialValue: initialFlow)
    }

    var body: some View {
        NavigationStack {
            content
                .animation(.default, value: flowState.animationID)
                .toolbar {
                    if shouldShowReportListButton {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                isShowingReportList = true
                            } label: {
                                Label("Звіти", systemImage: "doc.text").labelStyle(.iconOnly)
                            }
                            .accessibilityLabel("Збережені звіти")
                        }
                    }
                }
        }
        .alert("Щось пішло не так", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("Гаразд", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Невідома помилка")
        }
        .sheet(isPresented: $isShowingReportList) {
            ReportListView()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch flowState {
        case .onboarding:
            OnboardingView(
                viewModel: onboardingViewModel,
                onFinish: {
                    withAnimation {
                        flowState = .birthInput(existing: nil)
                    }
                }
            )

        case .birthInput(let existing):
            BirthDataInputView(
                viewModel: BirthDataInputViewModel(initialDetails: existing),
                onContinue: { details in
                    calculateChart(for: details)
                },
                onCancel: nil
            )

        case .calculating(let details):
            CalculatingChartView(
                birthDetails: details
            )

        case .areaSelection(let details, let chart):
            AreaSelectionView(
                birthDetails: details,
                natalChart: chart,
                onAreaSelected: { area in
                    flowState = .purchase(details, chart, area)
                },
                onEditDetails: {
                    flowState = .birthInput(existing: details)
                }
            )

        case .purchase(let details, let chart, let area):
            PurchaseConfirmationView(
                birthDetails: details,
                area: area,
                onBack: {
                    flowState = .areaSelection(details, chart)
                },
                onGenerateReport: {
                    generateReport(details: details, chart: chart, area: area)
                }
            )

        case .generating(let details, let chart, let area):
            GeneratingReportView(
                birthDetails: details,
                area: area,
                onCancel: {
                    flowState = .purchase(details, chart, area)
                }
            )

        case .report(let details, let chart, _, let report):
            ReportDetailView(
                birthDetails: details,
                natalChart: chart,
                report: report,
                onGenerateAnother: {
                    flowState = .areaSelection(details, chart)
                },
                onStartOver: {
                    flowState = .birthInput(existing: nil)
                }
            )
        }
    }

    private func calculateChart(for details: BirthDetails) {
        flowState = .calculating(details)

        Task {
            do {
                guard let coordinate = details.coordinate else {
                    throw ChartCalculationError.missingCoordinate
                }

                let chart = try await chartCalculator.calculate(
                    birthDate: details.birthDate,
                    birthTime: details.birthTime,
                    timeZoneIdentifier: details.timeZone.identifier,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    locationName: details.location
                )

                // Print chart data to console
                printChartData(chart)

                await MainActor.run {
                    flowState = .areaSelection(details, chart)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Не вдалося розрахувати карту: \(error.localizedDescription)"
                    flowState = .birthInput(existing: details)
                }
            }
        }
    }

    private func generateReport(details: BirthDetails, chart: NatalChart, area: ReportArea) {
        flowState = .generating(details, chart, area)

        Task {
            do {
                let report = try await reportGenerator.generateReport(
                    for: area,
                    birthDetails: details,
                    natalChart: chart
                )
                do {
                    try await persistGeneratedReport(
                        details: details,
                        natalChart: chart,
                        generatedReport: report
                    )
                } catch {
                    #if DEBUG
                    print("⚠️ Не вдалося зберегти звіт: \(error)")
                    #endif
                }
                await MainActor.run {
                    flowState = .report(details, chart, area, report)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    flowState = .purchase(details, chart, area)
                }
            }
        }
    }

    private func printChartData(_ chart: NatalChart) {
        print("\n" + String(repeating: "=", count: 60))
        print("📊 NATAL CHART CALCULATION RESULTS")
        print(String(repeating: "=", count: 60))

        print("\n🔮 ANGLES:")
        print("   Ascendant: \(formatDegree(chart.ascendant)) (\(ZodiacSign.from(degree: chart.ascendant).rawValue))")
        print("   Midheaven: \(formatDegree(chart.midheaven)) (\(ZodiacSign.from(degree: chart.midheaven).rawValue))")

        print("\n🪐 PLANETS (\(chart.planets.count)):")
        for planet in chart.planets {
            let retro = planet.isRetrograde ? " ℞" : ""
            print("   \(planet.name.rawValue.padding(toLength: 8, withPad: " ", startingAt: 0)): \(formatDegree(planet.longitude)) \(planet.sign.rawValue.padding(toLength: 12, withPad: " ", startingAt: 0)) House \(planet.house)\(retro)")
            print("      └─ Speed: \(String(format: "%.4f", planet.speed))°/day")
        }

        print("\n🏠 HOUSES (\(chart.houses.count)):")
        for house in chart.houses.sorted(by: { $0.number < $1.number }) {
            print("   House \(String(format: "%2d", house.number)): \(formatDegree(house.cusp)) (\(house.sign.rawValue))")
        }

        print("\n⚡️ ASPECTS (\(chart.aspects.count)):")
        for aspect in chart.aspects {
            print("   \(aspect.planet1.rawValue) \(aspectSymbol(aspect.type)) \(aspect.planet2.rawValue) - \(aspect.type.rawValue) (orb: \(String(format: "%.2f", aspect.orb))°)")
        }

        print("\n📅 Calculated at: \(chart.calculatedAt.formatted(date: .abbreviated, time: .standard))")
        print(String(repeating: "=", count: 60) + "\n")
    }

    private func formatDegree(_ degree: Double) -> String {
        let normalized = degree.truncatingRemainder(dividingBy: 360)
        let degrees = Int(normalized)
        let minutes = Int((normalized - Double(degrees)) * 60)
        return String(format: "%3d°%02d'", degrees, minutes)
    }

    private func aspectSymbol(_ type: AspectType) -> String {
        switch type {
        case .conjunction: return "☌"
        case .opposition: return "☍"
        case .trine: return "△"
        case .square: return "□"
        case .sextile: return "⚹"
        }
    }
}

enum ChartCalculationError: LocalizedError {
    case missingCoordinate

    var errorDescription: String? {
        switch self {
        case .missingCoordinate:
            return "Не вказано координати місця народження"
        }
    }
}

// MARK: - Flow State

private enum FlowState {
    case onboarding
    case birthInput(existing: BirthDetails?)
    case calculating(BirthDetails)
    case areaSelection(BirthDetails, NatalChart)
    case purchase(BirthDetails, NatalChart, ReportArea)
    case generating(BirthDetails, NatalChart, ReportArea)
    case report(BirthDetails, NatalChart, ReportArea, GeneratedReport)

    var animationID: String {
        switch self {
        case .onboarding: return "onboarding"
        case .birthInput: return "birthInput"
        case .calculating: return "calculating"
        case .areaSelection: return "areaSelection"
        case .purchase: return "purchase"
        case .generating: return "generating"
        case .report: return "report"
        }
    }
}

private extension ContentView {
    var shouldShowReportListButton: Bool {
        if case .onboarding = flowState {
            return false
        }
        return true
    }

    @MainActor
    func persistGeneratedReport(details: BirthDetails, natalChart: NatalChart, generatedReport: GeneratedReport) throws {
        let chartEntity = try upsertBirthChart(details: details, natalChart: natalChart)

        let reportText = renderReportText(from: generatedReport)
        let languageCode = Locale.current.languageCode ?? "uk"

        let purchase = ReportPurchase(
            area: generatedReport.area.rawValue,
            reportText: reportText,
            summary: generatedReport.summary,
            keyInfluences: generatedReport.keyInfluences,
            detailedAnalysis: generatedReport.detailedAnalysis,
            recommendations: generatedReport.recommendations,
            language: languageCode,
            price: generatedReport.area.price,
            transactionId: UUID().uuidString
        )

        purchase.chart = chartEntity
        modelContext.insert(purchase)
        try modelContext.save()
    }

    @MainActor
    func upsertBirthChart(details: BirthDetails, natalChart: NatalChart) throws -> BirthChart {
        let name = details.name
        let birthDate = details.birthDate
        let birthTime = details.birthTime
        let timezoneID = details.timeZone.identifier

        let descriptor = FetchDescriptor<BirthChart>(
            predicate: #Predicate { chart in
                chart.name == name &&
                chart.birthDate == birthDate &&
                chart.birthTime == birthTime &&
                chart.timezone == timezoneID
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        let matches = try modelContext.fetch(descriptor)

        let chartJSON = BirthChart.encodedChartJSON(from: natalChart) ?? ""
        let coordinate = details.coordinate

        if let existing = matches.first {
            existing.name = details.name
            existing.birthDate = details.birthDate
            existing.birthTime = details.birthTime
            existing.locationName = details.location
            existing.latitude = coordinate?.latitude ?? existing.latitude
            existing.longitude = coordinate?.longitude ?? existing.longitude
            existing.timezone = details.timeZone.identifier
            if chartJSON.isEmpty == false {
                existing.updateChartData(chartJSON)
            }
            existing.updatedAt = Date()
            return existing
        }

        let newChart = BirthChart(
            name: details.name,
            birthDate: details.birthDate,
            birthTime: details.birthTime,
            locationName: details.location,
            latitude: coordinate?.latitude ?? 0,
            longitude: coordinate?.longitude ?? 0,
            timezone: details.timeZone.identifier,
            chartDataJSON: chartJSON
        )

        modelContext.insert(newChart)
        return newChart
    }

    func renderReportText(from report: GeneratedReport) -> String {
        var lines: [String] = []
        lines.append(report.summary)

        if report.keyInfluences.isEmpty == false {
            lines.append("")
            lines.append("Ключові впливи:")
            report.keyInfluences.forEach { lines.append("• \($0)") }
        }

        lines.append("")
        lines.append("Детальний аналіз:")
        lines.append(report.detailedAnalysis)

        if report.recommendations.isEmpty == false {
            lines.append("")
            lines.append("Рекомендації:")
            report.recommendations.forEach { lines.append("• \($0)") }
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - Supporting Views

private struct CalculatingChartView: View {
    let birthDetails: BirthDetails

    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)

            VStack(spacing: 8) {
                Text("Розраховуємо вашу натальну карту…")
                    .font(.headline)
                Text("Обчислюємо позиції планет, будинки та аспекти на момент вашого народження.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Розрахунок карти")
    }
}

private struct GeneratingReportView: View {
    let birthDetails: BirthDetails
    let area: ReportArea
    var onCancel: (() -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)

            VStack(spacing: 8) {
                Text("Створюємо ваш звіт для сфери «\(area.displayName.lowercased())»…")
                    .font(.headline)
                Text("Ми поєднуємо експертні астрологічні правила з вашими даними народження.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            if let onCancel {
                Button("Скасувати") {
                    onCancel()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Створення звіту")
    }
}

#Preview {
    ContentView()
}
