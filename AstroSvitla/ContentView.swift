import SwiftUI

struct ContentView: View {
    @State private var flowState: FlowState = .birthInput(existing: nil)
    @State private var errorMessage: String?

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
                    flowState = .areaSelection(details)
                },
                onCancel: nil
            )

        case .areaSelection(let details):
            AreaSelectionView(
                birthDetails: details,
                onAreaSelected: { area in
                    flowState = .purchase(details, area)
                },
                onEditDetails: {
                    flowState = .birthInput(existing: details)
                }
            )

        case .purchase(let details, let area):
            PurchaseConfirmationView(
                birthDetails: details,
                area: area,
                onBack: {
                    flowState = .areaSelection(details)
                },
                onGenerateReport: {
                    generateReport(details: details, area: area)
                }
            )

        case .generating(let details, let area):
            GeneratingReportView(
                birthDetails: details,
                area: area,
                onCancel: {
                    flowState = .purchase(details, area)
                }
            )

        case .report(let details, let area, let report):
            ReportDetailView(
                birthDetails: details,
                report: report,
                onGenerateAnother: {
                    flowState = .areaSelection(details)
                },
                onStartOver: {
                    flowState = .birthInput(existing: nil)
                }
            )
        }
    }

    private func generateReport(details: BirthDetails, area: ReportArea) {
        let demoDetails = ReportGenerationDemoData.sampleBirthDetails
        flowState = .generating(demoDetails, area)

        Task {
            do {
                let report = try await reportGenerator.generateReport(for: area, birthDetails: demoDetails)
                await MainActor.run {
                    flowState = .report(demoDetails, area, report)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    flowState = .purchase(demoDetails, area)
                }
            }
        }
    }
}

// MARK: - Flow State

private enum FlowState {
    case birthInput(existing: BirthDetails?)
    case areaSelection(BirthDetails)
    case purchase(BirthDetails, ReportArea)
    case generating(BirthDetails, ReportArea)
    case report(BirthDetails, ReportArea, GeneratedReport)

    var animationID: String {
        switch self {
        case .birthInput: return "birthInput"
        case .areaSelection: return "areaSelection"
        case .purchase: return "purchase"
        case .generating: return "generating"
        case .report: return "report"
        }
    }
}

// MARK: - Supporting Views

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
