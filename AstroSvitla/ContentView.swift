import SwiftUI
import CoreLocation

struct ContentView: View {
    @State private var flowState: FlowState = .birthInput(existing: nil)
    @State private var errorMessage: String?

    private let chartCalculator = ChartCalculator()
    private let reportGenerator = AIReportGenerator()

    var body: some View {
        NavigationStack {
            content
                .animation(.default, value: flowState.animationID)
        }
        .alert("Щось пішло не так", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("Гаразд", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Невідома помилка")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch flowState {
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
    case birthInput(existing: BirthDetails?)
    case calculating(BirthDetails)
    case areaSelection(BirthDetails, NatalChart)
    case purchase(BirthDetails, NatalChart, ReportArea)
    case generating(BirthDetails, NatalChart, ReportArea)
    case report(BirthDetails, NatalChart, ReportArea, GeneratedReport)

    var animationID: String {
        switch self {
        case .birthInput: return "birthInput"
        case .calculating: return "calculating"
        case .areaSelection: return "areaSelection"
        case .purchase: return "purchase"
        case .generating: return "generating"
        case .report: return "report"
        }
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
