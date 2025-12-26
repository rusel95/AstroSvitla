import SwiftUI
import UIKit
import CoreLocation
import SwiftData
import Sentry
import StoreKit

enum ChartCalculationError: LocalizedError {
    case missingCoordinate

    var errorDescription: String? {
        switch self {
        case .missingCoordinate:
            return String(localized: "error.coordinates_not_found")
        }
    }
}

struct MainFlowView: View {
    @EnvironmentObject private var preferences: AppPreferences
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var repositoryContext: RepositoryContext
    @Environment(RevenueCatPurchaseService.self) private var purchaseService
    @Environment(CreditManager.self) private var creditManager
    @StateObject private var profileViewModel: UserProfileViewModel
    @State private var flowState: FlowState = .birthInput
    @State private var navigationPath = NavigationPath()
    @State private var errorMessage: String?
    @State private var showProfileCreationSheet = false
    @State private var generationOverlay: GenerationOverlayData?

    private var chartCalculator: ChartCalculator {
        ChartCalculator(modelContext: modelContext)
    }
    private let reportGenerator = AIReportGenerator()

    init(modelContext: ModelContext, repositoryContext: RepositoryContext) {
        self.repositoryContext = repositoryContext
        let service = UserProfileService(context: modelContext)
        let profileVM = UserProfileViewModel(service: service, repositoryContext: repositoryContext)
        _profileViewModel = StateObject(wrappedValue: profileVM)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            rootContent
                .animation(.default, value: flowState.animationID)
                .navigationDestination(for: MainNavDestination.self) { destination in
                    destinationView(for: destination)
                }
        }
        .alert(Text("error.title", bundle: .main), isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? String(localized: "error.generic"))
        }
        .fullScreenCover(item: $generationOverlay) { overlay in
            GeneratingReportView(
                birthDetails: overlay.details,
                area: overlay.area,
                onCancel: {
                    generationOverlay = nil
                }
            )
            .task {
                await performReportGeneration(overlay: overlay)
            }
        }
        .onAppear {
            profileViewModel.loadProfiles()
        }
    }


    // MARK: - Root Content (non-navigable states)

    @ViewBuilder
    private var rootContent: some View {
        switch flowState {
        case .birthInput:
            Group {
                if profileViewModel.profiles.isEmpty {
                    ProfileEmptyStateView(onCreateProfile: {
                        showProfileCreationSheet = true
                    })
                    .navigationBarHidden(true)
                } else {
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
                    .navigationBarHidden(true)
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
            CalculatingChartView(birthDetails: details)

        case .generating(let details, _, let area):
            GeneratingReportView(
                birthDetails: details,
                area: area,
                onCancel: {
                    navigationPath.removeLast()
                }
            )
        }
    }

    // MARK: - Navigation Destinations (navigable states with native back)

    @ViewBuilder
    private func destinationView(for destination: MainNavDestination) -> some View {
        switch destination {
        case .areaSelection(let details, let chart):
            AreaSelectionView(
                birthDetails: details,
                natalChart: chart,
                purchasedAreas: getPurchasedAreas(),
                purchaseService: purchaseService,
                hasCredit: creditManager.hasAvailableCredits(),
                onAreaSelected: { area in
                    navigationPath.append(MainNavDestination.purchase(details, chart, area))
                },
                onViewExistingReport: { area in
                    viewExistingReport(for: area, details: details, chart: chart)
                }
            )

        case .purchase(let details, let chart, let area):
            if let profile = repositoryContext.activeProfile,
               profile.reports.contains(where: { $0.isForArea(area) }) {
                Color.clear.onAppear {
                    viewExistingReport(for: area, details: details, chart: chart)
                }
            } else {
                PurchaseConfirmationView(
                    birthDetails: details,
                    area: area,
                    purchaseService: purchaseService,
                    hasCredit: creditManager.hasAvailableCredits(),
                    onBack: nil, // Native back button handles this
                    onGenerateReport: {
                        // Generate report first, then consume credit only on success
                        Task {
                            if let profile = repositoryContext.activeProfile {
                                await MainActor.run {
                                    generateReport(
                                        details: details,
                                        chart: chart,
                                        area: area,
                                        consumeCreditProfileID: profile.id
                                    )
                                }
                            } else {
                                await MainActor.run { errorMessage = String(localized: "error.profile.select") }
                            }
                        }
                    },
                    onPurchase: {
                        Task {
                            #if DEBUG
                            print("💳 [MainFlowView] Purchase button tapped")
                            #endif
                            
                            do {
                                #if DEBUG
                                print("💳 [MainFlowView] Starting purchase via RevenueCat")
                                #endif
                                
                                _ = try await purchaseService.purchaseSingleCredit()
                                
                                #if DEBUG
                                print("✅ [MainFlowView] Purchase completed!")
                                #endif
                                
                                // After successful purchase, automatically generate report
                                if let profile = repositoryContext.activeProfile {
                                    #if DEBUG
                                    print("🚀 [MainFlowView] Auto-triggering report generation after purchase")
                                    #endif
                                    
                                    await MainActor.run {
                                        generateReport(
                                            details: details,
                                            chart: chart,
                                            area: area,
                                            consumeCreditProfileID: profile.id
                                        )
                                    }
                                } else {
                                    await MainActor.run {
                                        errorMessage = String(localized: "error.profile.select")
                                    }
                                }
                                
                            } catch let error as PurchaseError {
                                // Show user-facing error alert (skip userCancelled)
                                #if DEBUG
                                print("❌ [MainFlowView] Purchase error: \(error)")
                                #endif
                                
                                await MainActor.run {
                                    if case .userCancelled = error {
                                        // Don't show error for user cancellation
                                        return
                                    }
                                    if let errorDesc = error.errorDescription {
                                        errorMessage = errorDesc
                                    } else {
                                        errorMessage = String(localized: "purchase.error.purchase_failed", defaultValue: "Purchase failed. Please try again.")
                                    }
                                }
                            } catch {
                                // Handle unexpected errors
                                #if DEBUG
                                print("❌ [MainFlowView] Unexpected error: \(error)")
                                #endif
                                
                                await MainActor.run {
                                    errorMessage = String(localized: "purchase.error.purchase_failed", defaultValue: "Purchase failed. Please try again.")
                                }
                            }
                        }
                    }
                )
            }

        case .report(let details, let chart, _, let report):
            ReportDetailView(
                birthDetails: details,
                natalChart: chart,
                report: report
            )
        }
    }

    // MARK: - Profile Creation & Management

    /// Creates a new profile with the provided data
    /// Profile is saved first. Chart will be fetched lazily when user clicks "Continue"
    private func createNewProfile(
        name: String,
        birthDate: Date,
        birthTime: Date,
        location: String,
        coordinate: CLLocationCoordinate2D,
        timezone: String
    ) {
        // Save profile FIRST (so user data is never lost)
        // Chart will be fetched when user clicks "Continue" button
        guard let newProfile = profileViewModel.createProfileWithoutChart(
            name: name,
            birthDate: birthDate,
            birthTime: birthTime,
            locationName: location,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            timezone: timezone
        ) else {
            errorMessage = profileViewModel.errorMessage ?? String(localized: "error.profile.create")
            return
        }

        // Profile saved - set as active
        repositoryContext.setActiveProfile(newProfile)
        profileViewModel.loadProfiles()

        #if DEBUG
        print("[MainFlowView] ✅ Profile saved: \(name). Chart will be fetched on Continue.")
        #endif
    }

    /// Continues with the currently selected profile
    private func handleContinueWithSelectedProfile() async {
        guard let profile = repositoryContext.activeProfile else {
            await MainActor.run {
                errorMessage = String(localized: "error.profile.select")
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

        // Check if profile already has a cached chart
        if let existingChart = profile.chart, let natalChart = existingChart.decodedNatalChart() {
            #if DEBUG
            print("[MainFlowView] ✅ Using existing chart from profile")
            #endif
            await MainActor.run {
                navigationPath.append(MainNavDestination.areaSelection(details, natalChart))
            }
            return
        }

        // No cached chart - need to fetch from API
        await MainActor.run {
            flowState = .calculating(details)
        }

        do {
            let chart = try await calculateChart(for: details)

            // Save chart to profile for future use
            _ = await MainActor.run {
                profileViewModel.attachChart(to: profile, natalChart: chart)
            }

            await MainActor.run {
                flowState = .birthInput
                navigationPath.append(MainNavDestination.areaSelection(details, chart))
            }
        } catch {
            await MainActor.run {
                let baseError = String(localized: "error.chart.fetch")
                errorMessage = "\(baseError): \(error.localizedDescription)"
                flowState = .birthInput
            }
        }
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

    // MARK: - Duplicate Report Prevention

    /// Returns the set of areas that have already been purchased for the active profile
    private func getPurchasedAreas() -> Set<ReportArea> {
        guard let profile = repositoryContext.activeProfile else {
            return []
        }
        return Set(profile.reports.compactMap { ReportArea(rawValue: $0.area) })
    }

    /// Navigates to view an existing report for the given area
    private func viewExistingReport(for area: ReportArea, details: BirthDetails, chart: NatalChart) {
        guard let profile = repositoryContext.activeProfile,
              let existingReport = profile.reports.first(where: { $0.isForArea(area) }),
              let generatedReport = existingReport.generatedReport else {
            // Fallback: if we can't find the report, show error
            errorMessage = String(localized: "error.report.not_found")
            return
        }

        navigationPath.append(MainNavDestination.report(details, chart, area, generatedReport))
    }

    private func generateReport(
        details: BirthDetails,
        chart: NatalChart,
        area: ReportArea,
        consumeCreditProfileID: UUID? = nil
    ) {
        // Show generation overlay on top of current navigation
        generationOverlay = GenerationOverlayData(
            details: details,
            chart: chart,
            area: area,
            consumeCreditProfileID: consumeCreditProfileID
        )
    }
    
    private func performReportGeneration(overlay: GenerationOverlayData) async {
        let languageCode = LocaleHelper.currentLanguageCode
        let languageDisplayName = LocaleHelper.currentLanguageDisplayName
        
        // Configuration for retries
        let maxRetries = 3
        let baseDelaySeconds: UInt64 = 2
        
        // Request background time to complete generation
        var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "ReportGeneration") {
            // Background time expired - task will be cancelled
            #if DEBUG
            print("⚠️ [MainFlowView] Background time expired during report generation")
            #endif
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
        }
        
        defer {
            // End background task when done
            if backgroundTaskID != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
            }
        }
        
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                #if DEBUG
                if attempt > 1 {
                    print("🔄 [MainFlowView] Report generation retry attempt \(attempt)/\(maxRetries)")
                }
                #endif
                
                let report = try await reportGenerator.generateReport(
                    for: overlay.area,
                    birthDetails: overlay.details,
                    natalChart: overlay.chart,
                    languageCode: languageCode,
                    languageDisplayName: languageDisplayName,
                    repositoryContext: "Zorya iOS app",
                    selectedModel: preferences.selectedModel
                )
                
                // Success! Consume credit and persist report
                if let profileID = overlay.consumeCreditProfileID {
                    do {
                        _ = try creditManager.consumeCredit(for: overlay.area.rawValue, profileID: profileID)
                    } catch {
                        #if DEBUG
                        print("⚠️ [MainFlowView] Failed to consume credit after report generation: \(error)")
                        #endif
                        SentrySDK.capture(error: error) { scope in
                            scope.setLevel(.warning)
                            scope.setTag(value: "credit_consumption", key: "issue")
                            scope.setTag(value: "post_generation", key: "phase")
                            scope.setContext(value: [
                                "message": "Failed to consume credit after successful report generation",
                                "report_area": overlay.area.rawValue
                            ], key: "error_context")
                        }
                    }
                }

                do {
                    try persistGeneratedReport(
                        details: overlay.details,
                        natalChart: overlay.chart,
                        generatedReport: report
                    )
                } catch {
                    #if DEBUG
                    print("⚠️ Помилка збереження звіту: \(error)")
                    #endif
                }

                await MainActor.run {
                    // Dismiss overlay and navigate to report
                    generationOverlay = nil
                    // Clear navigation to purchase if present, then push report
                    while navigationPath.count > 1 {
                        navigationPath.removeLast()
                    }
                    navigationPath.append(MainNavDestination.report(overlay.details, overlay.chart, overlay.area, report))
                }
                
                // Success - exit retry loop
                return
                
            } catch {
                lastError = error
                
                #if DEBUG
                print("❌ [MainFlowView] Report generation failed (attempt \(attempt)/\(maxRetries)): \(error.localizedDescription)")
                #endif
                
                // Check if this is a retryable error
                let isRetryable = isRetryableError(error)
                
                if attempt < maxRetries && isRetryable {
                    // Wait with exponential backoff before retrying
                    let delay = baseDelaySeconds * UInt64(pow(2.0, Double(attempt - 1)))
                    try? await Task.sleep(nanoseconds: delay * 1_000_000_000)
                } else {
                    // No more retries or non-retryable error
                    break
                }
            }
        }
        
        // All retries failed
        await MainActor.run {
            generationOverlay = nil
            errorMessage = lastError?.localizedDescription ?? String(localized: "error.report.generation_failed", defaultValue: "Report generation failed. Please try again.")
        }
    }
    
    /// Determines if an error should trigger a retry
    private func isRetryableError(_ error: Error) -> Bool {
        // Network errors are retryable
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost:
                return true
            default:
                return false
            }
        }
        
        // Check for transient server errors (5xx)
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain || nsError.domain == "OpenAIServiceError" {
            return true
        }
        
        return false
    }

    private func printChartData(_ chart: NatalChart) {
#if DEBUG
        guard Config.debugLoggingEnabled else { return }
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
#endif
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
        let languageCode = LocaleHelper.currentLanguageCode

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
            languageCode: languageCode,
            knowledgeVectorUsed: generatedReport.knowledgeUsage.vectorSourceUsed,
            knowledgeNotes: generatedReport.knowledgeUsage.notes,
            knowledgeSourceTitles: sourceTitles.isEmpty ? nil : sourceTitles,
            knowledgeSourceAuthors: sourceAuthors.isEmpty ? nil : sourceAuthors,
            knowledgeSourcePages: sourcePages.isEmpty ? nil : sourcePages,
            price: 0.00, // Price tracking removed - IAP system handles this via PurchaseRecord
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

    func renderReportText(from report: GeneratedReport) -> String {
        var lines: [String] = []
        lines.append(report.summary)

        if report.keyInfluences.isEmpty == false {
            lines.append("")
            lines.append(String(localized: "report.section.key_influences"))
            report.keyInfluences.forEach { lines.append("• \($0)") }
        }

        lines.append("")
        lines.append(String(localized: "report.section.analysis"))
        lines.append(report.detailedAnalysis)

        if report.recommendations.isEmpty == false {
            lines.append("")
            lines.append(String(localized: "report.section.recommendations"))
            report.recommendations.forEach { lines.append("• \($0)") }
        }

        lines.append("")
        lines.append(report.knowledgeUsage.vectorSourceUsed ? String(localized: "report.sources.used") : String(localized: "report.sources.not_used"))
        if let notes = report.knowledgeUsage.notes, notes.isEmpty == false {
            lines.append(String(localized: "report.note_prefix \(notes)"))
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - Generation Overlay Data

struct GenerationOverlayData: Identifiable {
    let id = UUID()
    let details: BirthDetails
    let chart: NatalChart
    let area: ReportArea
    let consumeCreditProfileID: UUID?
}

// MARK: - Flow State (kept for non-navigation state tracking)

private enum FlowState: Equatable {
    case birthInput
    case calculating(BirthDetails)
    case generating(BirthDetails, NatalChart, ReportArea)

    static func == (lhs: FlowState, rhs: FlowState) -> Bool {
        switch (lhs, rhs) {
        case (.birthInput, .birthInput): return true
        case (.calculating(let l), .calculating(let r)): return l.displayName == r.displayName
        case (.generating(let ld, _, let la), .generating(let rd, _, let ra)):
            return ld.displayName == rd.displayName && la == ra
        default: return false
        }
    }

    var animationID: String {
        switch self {
        case .birthInput: return "birthInput"
        case .calculating: return "calculating"
        case .generating: return "generating"
        }
    }
}

// MARK: - Navigation Destination

enum MainNavDestination: Hashable {
    case areaSelection(BirthDetails, NatalChart)
    case purchase(BirthDetails, NatalChart, ReportArea)
    case report(BirthDetails, NatalChart, ReportArea, GeneratedReport)

    func hash(into hasher: inout Hasher) {
        switch self {
        case .areaSelection(let details, _):
            hasher.combine("areaSelection")
            hasher.combine(details.displayName)
        case .purchase(let details, _, let area):
            hasher.combine("purchase")
            hasher.combine(details.displayName)
            hasher.combine(area)
        case .report(let details, _, let area, _):
            hasher.combine("report")
            hasher.combine(details.displayName)
            hasher.combine(area)
        }
    }

    static func == (lhs: MainNavDestination, rhs: MainNavDestination) -> Bool {
        switch (lhs, rhs) {
        case (.areaSelection(let ld, _), .areaSelection(let rd, _)):
            return ld.displayName == rd.displayName
        case (.purchase(let ld, _, let la), .purchase(let rd, _, let ra)):
            return ld.displayName == rd.displayName && la == ra
        case (.report(let ld, _, let la, _), .report(let rd, _, let ra, _)):
            return ld.displayName == rd.displayName && la == ra
        default:
            return false
        }
    }
}

// MARK: - Supporting Views

private struct CalculatingChartView: View {
    let birthDetails: BirthDetails

    @State private var animateRing = false
    @State private var animatePulse = false

    var body: some View {
        ZStack {
            // Premium cosmic background
            CosmicBackgroundView()

            VStack(spacing: 40) {
                Spacer()

                // Animated calculation visualization
                ZStack {
                    // Outer rotating ring
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                colors: [
                                    Color.accentColor.opacity(0.1),
                                    Color.accentColor.opacity(0.5),
                                    Color.accentColor,
                                    Color.accentColor.opacity(0.5),
                                    Color.accentColor.opacity(0.1)
                                ],
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(animateRing ? 360 : 0))

                    // Middle pulsing circle
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .scaleEffect(animatePulse ? 1.1 : 0.95)

                    // Inner glass circle
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                        )

                    // Center icon
                    Image(systemName: "sparkles")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: Color.accentColor.opacity(0.2), radius: 20, x: 0, y: 10)

                // Text content
                VStack(spacing: 12) {
                    Text("loading.calculating.title", bundle: .main)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("loading.calculating.description \(birthDetails.displayName)", bundle: .main)
                        .font(.system(size: 15, weight: .regular))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 32)
                }

                Spacer()

                // Progress indicators
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 8, height: 8)
                            .scaleEffect(animatePulse && index == 0 ? 1.3 :
                                        animatePulse && index == 1 ? 1.0 : 0.7)
                            .opacity(animatePulse && index == 0 ? 1.0 :
                                    animatePulse && index == 1 ? 0.7 : 0.4)
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .navigationTitle(Text("loading.calculating.navigation", bundle: .main))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(
                .linear(duration: 2)
                .repeatForever(autoreverses: false)
            ) {
                animateRing = true
            }
            withAnimation(
                .easeInOut(duration: 1)
                .repeatForever(autoreverses: true)
            ) {
                animatePulse = true
            }
        }
    }
}

private struct GeneratingReportView: View {
    let birthDetails: BirthDetails
    let area: ReportArea
    var onCancel: (() -> Void)?

    @State private var animateWave = false
    @State private var pulsate = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var wasInBackground = false

    var body: some View {
        ZStack {
            // Premium cosmic background
            CosmicBackgroundView()

            VStack(spacing: 36) {
                Spacer()

                // Animated generation visualization - bubble style
                ZStack {
                    // Outer pulsating glow
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 180, height: 180)
                        .scaleEffect(pulsate ? 1.1 : 0.95)
                        .blur(radius: 20)
                        .animation(
                            .easeInOut(duration: 2)
                            .repeatForever(autoreverses: true),
                            value: pulsate
                        )

                    // Wave circles
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                Color.accentColor.opacity(0.3 - Double(index) * 0.1),
                                lineWidth: 2
                            )
                            .frame(width: 100 + CGFloat(index) * 40)
                            .scaleEffect(animateWave ? 1.2 : 1.0)
                            .opacity(animateWave ? 0 : 1)
                            .animation(
                                .easeOut(duration: 2)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.5),
                                value: animateWave
                            )
                    }

                    // Center glass container - main bubble
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 20, x: 0, y: 10)
                        .scaleEffect(pulsate ? 1.05 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                            value: pulsate
                        )

                    // Area icon
                    Image(systemName: area.icon)
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                // Text content
                VStack(spacing: 16) {
                    Text(String(localized: "loading.generating.title"))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text(String(localized: "loading.generating.description") + " \(area.displayName)")
                        .font(.system(size: 16, weight: .regular))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 32)
                        .lineSpacing(4)
                }

                // Time estimate bubble
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.system(size: 14, weight: .medium))
                        Text("loading.generating.time_estimate", bundle: .main)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                
                // "Keep app open" warning - styled to match the design
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.orange)
                    
                    Text(String(localized: "loading.generating.keep_open", 
                         defaultValue: "Please keep the app open while your report is being created"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.orange.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.orange.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)

                Spacer()

                // Cancel button
                if let onCancel {
                    Button(action: onCancel) {
                        Text("action.cancel", bundle: .main)
                    }
                    .buttonStyle(.astroSecondary)
                    .padding(.horizontal, 48)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle(Text("loading.generating.navigation", bundle: .main))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            animateWave = true
            pulsate = true
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                wasInBackground = true
                #if DEBUG
                print("⚠️ [GeneratingReportView] App moved to background during generation")
                #endif
            } else if newPhase == .active && wasInBackground {
                wasInBackground = false
                #if DEBUG
                print("✅ [GeneratingReportView] App returned to foreground")
                #endif
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer.astroSvitlaShared(inMemory: true)
    let repositoryContext = RepositoryContext(context: container.mainContext)
    MainFlowView(modelContext: container.mainContext, repositoryContext: repositoryContext)
        .environmentObject(AppPreferences())
}
