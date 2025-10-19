import SwiftUI
import CoreLocation
import SwiftData

enum ChartCalculationError: LocalizedError {
    case missingCoordinate

    var errorDescription: String? {
        switch self {
        case .missingCoordinate:
            return "Координати не знайдені"
        }
    }
}

struct MainFlowView: View {
    @EnvironmentObject private var preferences: AppPreferences
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var repositoryContext: RepositoryContext
    @StateObject private var onboardingViewModel: OnboardingViewModel
    @StateObject private var profileViewModel: UserProfileViewModel
    @State private var flowState: FlowState
    @State private var errorMessage: String?
    @State private var showProfileCreationSheet = false

    private var chartCalculator: ChartCalculator {
        ChartCalculator(modelContext: modelContext)
    }
    private let reportGenerator = AIReportGenerator()

    init(modelContext: ModelContext) {
        let onboardingViewModel = OnboardingViewModel()
        _onboardingViewModel = StateObject(wrappedValue: onboardingViewModel)

        let service = UserProfileService(context: modelContext)
        let repoContext = RepositoryContext(context: modelContext)
        let profileVM = UserProfileViewModel(service: service, repositoryContext: repoContext)
        _profileViewModel = StateObject(wrappedValue: profileVM)

        let initialFlow: FlowState = onboardingViewModel.isCompleted ? .birthInput(existing: nil) : .onboarding
        _flowState = State(initialValue: initialFlow)
    }

    var body: some View {
        NavigationStack {
            content
                .animation(.default, value: flowState.animationID)
        }
        .alert("Помилка", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Щось пішло не так")
        }
        .onAppear {
            profileViewModel.loadProfiles()
            repositoryContext.loadActiveProfile()
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
                        presentBirthInput(with: nil)
                    }
                }
            )

        case .birthInput(_):
            Group {
                if profileViewModel.profiles.isEmpty {
                    // Empty state - no profiles exist
                    ProfileEmptyStateView(onCreateProfile: {
                        showProfileCreationSheet = true
                    })
                    .navigationTitle("Початок")
                } else {
                    // Profile selection screen
                    ProfileSelectionView(
                        profiles: profileViewModel.profiles,
                        selectedProfile: repositoryContext.activeProfile,
                        onSelectProfile: { profile in
                            repositoryContext.setActiveProfile(profile)
                        },
                        onCreateNewProfile: {
                            showProfileCreationSheet = true
                        },
                        onContinue: {
                            Task {
                                await handleContinueWithSelectedProfile()
                            }
                        }
                    )
                    .navigationTitle("Профілі")
                }
            }
            .sheet(isPresented: $showProfileCreationSheet) {
                ProfileCreationSheet { name, birthDate, birthTime, location, coordinate, timezone in
                    createNewProfile(
                        name: name,
                        birthDate: birthDate,
                        birthTime: birthTime,
                        location: location,
                        coordinate: coordinate,
                        timezone: timezone
                    )
                }
            }

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
                }
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        presentBirthInput(with: details)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Назад")
                        }
                    }
                }
            }

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

        case .report(let details, let chart, let area, let report):
            ReportDetailView(
                birthDetails: details,
                natalChart: chart,
                report: report
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        flowState = .areaSelection(details, chart)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Назад")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Profile Creation & Management

    /// Creates a new profile with the provided data
    private func createNewProfile(
        name: String,
        birthDate: Date,
        birthTime: Date,
        location: String,
        coordinate: CLLocationCoordinate2D,
        timezone: String
    ) {
        Task {
            do {
                // Calculate natal chart first
                let timeZone = TimeZone(identifier: timezone) ?? .current
                let details = BirthDetails(
                    name: name,
                    birthDate: birthDate,
                    birthTime: birthTime,
                    location: location,
                    timeZone: timeZone,
                    coordinate: coordinate
                )

                let chart = try await calculateChart(for: details)

                // Create profile with calculated chart
                let created = await profileViewModel.createProfile(
                    name: name,
                    birthDate: birthDate,
                    birthTime: birthTime,
                    locationName: location,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    timezone: timezone,
                    natalChart: chart
                )

                if created, let newProfile = profileViewModel.selectedProfile {
                    await MainActor.run {
                        repositoryContext.setActiveProfile(newProfile)
                        profileViewModel.loadProfiles()
                    }
                } else {
                    await MainActor.run {
                        errorMessage = profileViewModel.errorMessage ?? "Помилка створення профілю"
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    /// Continues with the currently selected profile
    private func handleContinueWithSelectedProfile() async {
        guard let profile = repositoryContext.activeProfile else {
            await MainActor.run {
                errorMessage = "Будь ласка, виберіть профіль"
            }
            return
        }

        let timeZone = TimeZone(identifier: profile.timezone) ?? .current
        let details = BirthDetails(
            name: profile.name,
            birthDate: profile.birthDate,
            birthTime: profile.birthTime,
            location: profile.locationName,
            timeZone: timeZone,
            coordinate: CLLocationCoordinate2D(
                latitude: profile.latitude,
                longitude: profile.longitude
            )
        )

        await MainActor.run {
            flowState = .calculating(details)
        }

        do {
            let chart = try await calculateChart(for: details)

            await MainActor.run {
                flowState = .areaSelection(details, chart)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                flowState = .birthInput(existing: nil)
            }
        }
    }

    private func presentBirthInput(with details: BirthDetails?) {
        flowState = .birthInput(existing: details)
    }

    private func calculateChart(for details: BirthDetails) async throws -> NatalChart {
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

        printChartData(chart)

        return chart
    }

    private func generateReport(details: BirthDetails, chart: NatalChart, area: ReportArea) {
        flowState = .generating(details, chart, area)

        Task {
            do {
                let report = try await reportGenerator.generateReport(
                    for: area,
                    birthDetails: details,
                    natalChart: chart,
                    languageCode: preferences.selectedLanguageCode,
                    languageDisplayName: preferences.selectedLanguageDisplayName,
                    repositoryContext: "AstroSvitla iOS app context",
                    selectedModel: preferences.selectedModel
                )
                do {
                    try await persistGeneratedReport(
                        details: details,
                        natalChart: chart,
                        generatedReport: report
                    )
                } catch {
                    #if DEBUG
                    print("⚠️ " + localized("log.report.persist_failed") + ": \(error)")
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
        case .quincunx: return "⚻"
        case .semisextile: return "⚺"
        case .semisquare: return "∠"
        case .sesquisquare: return "⚼"
        case .quintile: return "Q"
        case .biquintile: return "bQ"
        }
    }
}

private extension MainFlowView {
    @MainActor
    func persistGeneratedReport(details: BirthDetails, natalChart: NatalChart, generatedReport: GeneratedReport) throws {
        let reportText = renderReportText(from: generatedReport)
        let languageCode = preferences.selectedLanguageCode

        // Extract knowledge source data for storage
        let sources = generatedReport.knowledgeUsage.sources ?? []
        let sourceTitles = sources.map { $0.bookTitle }
        let sourceAuthors = sources.map { $0.author ?? "" }
        let sourcePages = sources.map { $0.pageRange ?? "" }

        // Encode full logging data as JSON
        let encoder = JSONEncoder()
        var metadataJSON: String? = nil
        var knowledgeSourcesJSON: String? = nil
        var availableBooksJSON: String? = nil

        do {
            let metadataData = try encoder.encode(generatedReport.metadata)
            metadataJSON = String(data: metadataData, encoding: .utf8)
        } catch {
            print("[MainFlowView] ⚠️ Failed to encode metadata: \(error)")
        }

        if !sources.isEmpty {
            do {
                let sourcesData = try encoder.encode(sources)
                knowledgeSourcesJSON = String(data: sourcesData, encoding: .utf8)
            } catch {
                print("[MainFlowView] ⚠️ Failed to encode sources: \(error)")
            }
        }

        if let availableBooks = generatedReport.knowledgeUsage.availableBooks, !availableBooks.isEmpty {
            do {
                let booksData = try encoder.encode(availableBooks)
                availableBooksJSON = String(data: booksData, encoding: .utf8)
            } catch {
                print("[MainFlowView] ⚠️ Failed to encode available books: \(error)")
            }
        }

        let purchase = ReportPurchase(
            area: generatedReport.area.rawValue,
            reportText: reportText,
            summary: generatedReport.summary,
            keyInfluences: generatedReport.keyInfluences,
            detailedAnalysis: generatedReport.detailedAnalysis,
            recommendations: generatedReport.recommendations,
            language: languageCode,
            knowledgeVectorUsed: generatedReport.knowledgeUsage.vectorSourceUsed,
            knowledgeNotes: generatedReport.knowledgeUsage.notes,
            knowledgeSourceTitles: sourceTitles.isEmpty ? nil : sourceTitles,
            knowledgeSourceAuthors: sourceAuthors.isEmpty ? nil : sourceAuthors,
            knowledgeSourcePages: sourcePages.isEmpty ? nil : sourcePages,
            price: generatedReport.area.price,
            transactionId: UUID().uuidString,
            metadataJSON: metadataJSON,
            knowledgeSourcesJSON: knowledgeSourcesJSON,
            availableBooksJSON: availableBooksJSON
        )

        // Link report to active profile
        if let activeProfile = repositoryContext.activeProfile {
            purchase.profile = activeProfile
            print("[MainFlowView] ✅ Linked report to profile: \(activeProfile.name)")
        } else {
            print("[MainFlowView] ⚠️ No active profile found when saving report")
        }

        modelContext.insert(purchase)
        try modelContext.save()

        print("[MainFlowView] ✅ Report saved successfully with full logging data")
    }

    @MainActor
    func upsertBirthChart(details: BirthDetails, natalChart: NatalChart) throws -> BirthChart {
        let name = details.name
        let birthDate = details.birthDate
        let birthTime = details.birthTime
        let timezoneID = details.timeZone.identifier

        // TODO: This logic needs complete rewrite for UserProfile architecture
        // For now, just create a new chart each time
        let chartJSON = BirthChart.encodedChartJSON(from: natalChart) ?? ""
        let newChart = BirthChart(chartDataJSON: chartJSON)

        modelContext.insert(newChart)
        return newChart
    }

    func renderReportText(from report: GeneratedReport) -> String {
        var lines: [String] = []
        lines.append(report.summary)

        if report.keyInfluences.isEmpty == false {
            lines.append("")
            lines.append("Ключові впливи")
            report.keyInfluences.forEach { lines.append("• \($0)") }
        }

        lines.append("")
        lines.append("Аналіз")
        lines.append(report.detailedAnalysis)

        if report.recommendations.isEmpty == false {
            lines.append("")
            lines.append("Рекомендації")
            report.recommendations.forEach { lines.append("• \($0)") }
        }

        lines.append("")
        lines.append(report.knowledgeUsage.vectorSourceUsed ? localized("report.export.vector_usage_true") : localized("report.export.vector_usage_false"))
        if let notes = report.knowledgeUsage.notes, notes.isEmpty == false {
            lines.append("\(localized("report.export.vector_note_prefix")): \(notes)")
        }

        return lines.joined(separator: "\n")
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

// MARK: - Supporting Views

private struct CalculatingChartView: View {
    let birthDetails: BirthDetails

    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)

            VStack(spacing: 8) {
                Text("Розрахунок")
                    .font(.headline)
                Text("Будь ласка, почекайте")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(Text("Розрахунок"))
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
            Text(localized("generating.title", area.displayName))
                    .font(.headline)
                Text("Аналізуємо дані")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            if let onCancel {
                Button(localized("action.cancel")) {
                    onCancel()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(Text("Генерування"))
    }
}

#Preview {
    let container = try! ModelContainer.astroSvitlaShared(inMemory: true)
    MainFlowView(modelContext: container.mainContext)
        .environmentObject(AppPreferences())
        .environmentObject(RepositoryContext(context: container.mainContext))
}
