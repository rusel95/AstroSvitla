import SwiftUI
import CoreLocation
import SwiftData

enum ChartCalculationError: LocalizedError {
    case missingCoordinate

    var errorDescription: String? {
        switch self {
        case .missingCoordinate:
            return String(localized: "error.chart.missing_coordinate", table: "Localizable")
        }
    }
}

// MARK: - Profile Form State Management
/// Manages the three states of the inline profile form:
/// - empty: No profiles exist (first-time user)
/// - viewing: Displaying an existing profile's data
/// - creating: User selected "Create New Profile"
enum ProfileFormMode: Equatable {
    case empty                    // No profiles exist yet
    case viewing(UserProfile)     // Existing profile selected
    case creating                 // "Create New" selected

    var isCreating: Bool {
        if case .creating = self { return true }
        return false
    }

    var currentProfile: UserProfile? {
        if case .viewing(let profile) = self { return profile }
        return nil
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
    @State private var isShowingLocationSearch = false

    // MARK: - Profile Form State
    // Form mode
    @State private var formMode: ProfileFormMode = .empty

    // Form field state
    @State private var editedName: String = ""
    @State private var editedBirthDate: Date = Date()
    @State private var editedBirthTime: Date = Date()
    @State private var editedLocation: String = ""
    @State private var editedCoordinate: CLLocationCoordinate2D? = nil
    @State private var editedTimezone: String = TimeZone.current.identifier

    // UI state
    @State private var isCalculating: Bool = false
    @State private var validationError: String? = nil
    @FocusState private var focusedField: ProfileField?

    private var chartCalculator: ChartCalculator {
        ChartCalculator(modelContext: modelContext)
    }
    private let reportGenerator = AIReportGenerator()

    private enum ProfileField: Hashable {
        case name
    }

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
        .alert(String(localized: "alert.generic.title", table: "Localizable"), isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button(String(localized: "action.ok", table: "Localizable"), role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? String(localized: "alert.generic.message", table: "Localizable"))
        }
        .onAppear {
            profileViewModel.loadProfiles()
            repositoryContext.loadActiveProfile()

            // Initialize form mode based on active profile
            if let activeProfile = repositoryContext.activeProfile {
                handleProfileSelection(activeProfile)
            } else if let firstProfile = profileViewModel.profiles.first {
                handleProfileSelection(firstProfile)
            } else {
                formMode = .empty
                handleCreateNewProfile()
            }
        }
        .onChange(of: repositoryContext.activeProfile) { _, newValue in
            if newValue?.id == formMode.currentProfile?.id {
                return
            }

            if let profile = newValue {
                handleProfileSelection(profile)
            } else if let firstProfile = profileViewModel.profiles.first {
                handleProfileSelection(firstProfile)
            } else {
                handleCreateNewProfile()
            }
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
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Menu {
                        ForEach(profileViewModel.profiles) { profile in
                            Button {
                                handleProfileSelection(profile)
                            } label: {
                                HStack {
                                    Text(profile.name)
                                    if profile.id == repositoryContext.activeProfile?.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }

                        Divider()

                        Button {
                            handleCreateNewProfile()
                        } label: {
                            Label(
                                String(localized: "profile.selector.create_new", table: "Localizable"),
                                systemImage: "plus.circle"
                            )
                        }
                    } label: {
                        HStack {
                            Text(formMode.currentProfile?.name ?? String(localized: "profile.selector.new_profile", table: "Localizable"))
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        TextField("profile.form.field.name", text: $editedName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .name)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)

                        VStack(alignment: .leading, spacing: 12) {
                            DatePicker("birth.field.date", selection: $editedBirthDate, in: birthDateRange, displayedComponents: .date)

                            DatePicker("birth.field.time", selection: $editedBirthTime, displayedComponents: .hourAndMinute)

                            Button {
                                isShowingLocationSearch = true
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("birth.field.location", tableName: "Localizable")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        Text(locationDisplayText)
                                            .foregroundStyle(locationDisplayColor)
                                            .lineLimit(2)
                                    }
                                    Spacer()
                                    Image(systemName: "mappin.and.ellipse")
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                            }
                        }
                    }

                    if let error = validationError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(Color.red)
                            .padding(.horizontal, 4)
                    }

                    Button {
                        Task {
                            await handleContinue()
                        }
                    } label: {
                        HStack {
                            if isCalculating {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            } else {
                                Text("action.continue", tableName: "Localizable")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isContinueButtonEnabled || isCalculating)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color(.systemGroupedBackground))
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(Text("birth.navigation.title", tableName: "Localizable"))
            .sheet(isPresented: $isShowingLocationSearch) {
                NavigationStack {
                    LocationSearchView(initialQuery: editedLocation) { suggestion in
                        applyLocationSuggestion(suggestion)
                        isShowingLocationSearch = false
                    }
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(String(localized: "action.close", table: "Localizable")) {
                                isShowingLocationSearch = false
                            }
                        }
                    }
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
                },
                onEditDetails: {
                    presentBirthInput(with: details)
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
                    presentBirthInput(with: nil)
                }
            )
        }
    }

    // MARK: - Profile Selection Handlers

    /// Updates form fields when user selects a profile from dropdown.
    /// Discards any unsaved changes per FR-065 (no confirmation dialog).
    private func handleProfileSelection(_ profile: UserProfile) {
        formMode = .viewing(profile)
        editedName = profile.name
        editedBirthDate = profile.birthDate
        editedBirthTime = profile.birthTime
        editedLocation = profile.locationName
        editedCoordinate = CLLocationCoordinate2D(
            latitude: profile.latitude,
            longitude: profile.longitude
        )
        editedTimezone = profile.timezone
        if repositoryContext.activeProfile?.id != profile.id {
            repositoryContext.setActiveProfile(profile)
        }
        validationError = nil
    }

    /// Clears form fields when user selects "Create New Profile".
    /// Discards any unsaved changes per FR-065 (no confirmation dialog).
    private func handleCreateNewProfile() {
        if profileViewModel.profiles.isEmpty {
            formMode = .empty
        } else {
            formMode = .creating
        }
        editedName = ""
        editedBirthDate = defaultBirthDate()
        editedBirthTime = defaultBirthTime()
        editedLocation = ""
        editedCoordinate = nil
        editedTimezone = TimeZone.current.identifier
        validationError = nil
    }

    private var isContinueButtonEnabled: Bool {
        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = editedLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty == false && trimmedLocation.isEmpty == false && editedCoordinate != nil
    }

    private var birthDateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let minDate = calendar.date(from: DateComponents(year: 1900)) ?? Date(timeIntervalSince1970: 0)
        let maxDate = calendar.date(from: DateComponents(year: 2100)) ?? Date.distantFuture
        return minDate...maxDate
    }

    private var locationDisplayText: String {
        if editedLocation.isEmpty {
            return String(localized: "profile.inline.location.placeholder", table: "Localizable")
        }
        return editedLocation
    }

    private var locationDisplayColor: Color {
        editedLocation.isEmpty ? .secondary : .primary
    }

    private func validateForm() async -> Bool {
        validationError = nil

        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = editedLocation.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedName.isEmpty == false else {
            validationError = String(localized: "profile.form.error.name_required", table: "Localizable")
            return false
        }

        guard trimmedName.count <= 50 else {
            validationError = String(localized: "profile.form.error.name_length", table: "Localizable")
            return false
        }

        let isDuplicate = profileViewModel.profiles.contains { profile in
            profile.name.compare(trimmedName, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame &&
            profile.id != formMode.currentProfile?.id
        }

        if isDuplicate {
            validationError = String(localized: "profile.form.error.name_duplicate", table: "Localizable")
            return false
        }

        guard trimmedLocation.isEmpty == false else {
            validationError = String(localized: "profile.form.error.location_required", table: "Localizable")
            return false
        }

        guard editedCoordinate != nil else {
            validationError = String(localized: "profile.form.error.missing_coordinate", table: "Localizable")
            return false
        }

        return true
    }

    private func makeBirthDetails() -> BirthDetails {
        let timeZone = TimeZone(identifier: editedTimezone) ?? .current
        return BirthDetails(
            name: editedName,
            birthDate: editedBirthDate,
            birthTime: editedBirthTime,
            location: editedLocation,
            timeZone: timeZone,
            coordinate: editedCoordinate
        )
    }

    private func applyLocationSuggestion(_ suggestion: LocationSuggestion) {
        editedLocation = suggestion.displayName
        editedCoordinate = suggestion.coordinate
        if let timeZone = suggestion.timeZone {
            editedTimezone = timeZone.identifier
        }
        validationError = nil
    }

    private func applyBirthDetails(_ details: BirthDetails) {
        editedName = details.name
        editedBirthDate = details.birthDate
        editedBirthTime = details.birthTime
        editedLocation = details.location
        editedCoordinate = details.coordinate
        editedTimezone = details.timeZone.identifier
        validationError = nil
    }

    private func defaultBirthDate() -> Date {
        Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    }

    private func defaultBirthTime() -> Date {
        Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
    }

    private func presentBirthInput(with details: BirthDetails?) {
        if let details {
            applyBirthDetails(details)
        } else {
            handleCreateNewProfile()
        }
        flowState = .birthInput(existing: details)
    }

    private func handleContinue() async {
        validationError = nil

        guard await validateForm() else { return }

        let details = makeBirthDetails()

        guard let coordinate = details.coordinate else {
            validationError = String(localized: "profile.form.error.missing_coordinate", table: "Localizable")
            return
        }

        await MainActor.run {
            isCalculating = true
            flowState = .calculating(details)
        }

        do {
            let chart = try await calculateChart(for: details)

            switch formMode {
            case .creating, .empty:
                let created = await profileViewModel.createProfile(
                    name: details.name,
                    birthDate: details.birthDate,
                    birthTime: details.birthTime,
                    locationName: details.location,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    timezone: details.timeZone.identifier,
                    natalChart: chart
                )

                guard created, let selected = profileViewModel.selectedProfile else {
                    await MainActor.run {
                        isCalculating = false
                        presentBirthInput(with: details)
                        validationError = profileViewModel.errorMessage ?? String(localized: "profile.form.error.unknown", table: "Localizable")
                    }
                    return
                }

                await MainActor.run {
                    handleProfileSelection(selected)
                }

            case .viewing(let profile):
                let updated = await profileViewModel.updateProfile(
                    profile,
                    name: details.name,
                    birthDate: details.birthDate,
                    birthTime: details.birthTime,
                    locationName: details.location,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    timezone: details.timeZone.identifier,
                    natalChart: chart
                )

                guard updated else {
                    await MainActor.run {
                        isCalculating = false
                        presentBirthInput(with: details)
                        validationError = profileViewModel.errorMessage ?? String(localized: "profile.form.error.unknown", table: "Localizable")
                    }
                    return
                }

                let refreshedProfile = profileViewModel.selectedProfile ?? profile
                await MainActor.run {
                    handleProfileSelection(refreshedProfile)
                }
            }

            await MainActor.run {
                isCalculating = false
                validationError = nil
                flowState = .areaSelection(details, chart)
            }
        } catch {
            await MainActor.run {
                isCalculating = false
                let description: String
                if let localizedError = error as? LocalizedError, let value = localizedError.errorDescription {
                    description = value
                } else {
                    description = localized("error.chart.calculation_failed", error.localizedDescription)
                }
                presentBirthInput(with: details)
                validationError = description
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
                    repositoryContext: "AstroSvitla iOS app context"
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
            transactionId: UUID().uuidString
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

        print("[MainFlowView] ✅ Report saved successfully")
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
            lines.append(String(localized: "report.export.key_influences_header", table: "Localizable"))
            report.keyInfluences.forEach { lines.append("• \($0)") }
        }

        lines.append("")
        lines.append(String(localized: "report.export.analysis_header", table: "Localizable"))
        lines.append(report.detailedAnalysis)

        if report.recommendations.isEmpty == false {
            lines.append("")
            lines.append(String(localized: "report.export.recommendations_header", table: "Localizable"))
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
                Text("calculating.title", tableName: "Localizable")
                    .font(.headline)
                Text("calculating.description", tableName: "Localizable")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(Text("calculating.navigation_title", tableName: "Localizable"))
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
                Text("generating.description", tableName: "Localizable")
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
        .navigationTitle(Text("generating.navigation_title", tableName: "Localizable"))
    }
}

#Preview {
    let container = try! ModelContainer.astroSvitlaShared(inMemory: true)
    MainFlowView(modelContext: container.mainContext)
        .environmentObject(AppPreferences())
        .environmentObject(RepositoryContext(context: container.mainContext))
}
