import Foundation
import Combine
import CoreLocation

@MainActor
final class BirthDataInputViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var name: String
    @Published var birthDate: Date
    @Published var birthTime: Date
    @Published var location: String
    @Published var timeZone: TimeZone
    @Published var coordinate: CLLocationCoordinate2D?
    @Published private(set) var isValid: Bool = false
    @Published private(set) var hasSavedData: Bool = false

    private var cancellables: Set<AnyCancellable> = []
    private let storage = BirthDetailsStorage.shared

    // MARK: - Init

    init(initialDetails: BirthDetails? = nil) {
        // Initialize with default values first
        self.name = ""
        self.birthDate = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
        self.birthTime = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
        self.location = ""
        self.timeZone = .current
        self.coordinate = nil

        // Now setup validation and auto-save
        setupValidation()
        setupAutoSave()

        // Then override with provided or saved details
        if let initialDetails {
            // Use provided details (e.g., when editing)
            self.name = initialDetails.name
            self.birthDate = initialDetails.birthDate
            self.birthTime = initialDetails.birthTime
            self.location = initialDetails.location
            self.timeZone = initialDetails.timeZone
            self.coordinate = initialDetails.coordinate
        } else {
            // Load saved data asynchronously
            loadSavedData()
        }
    }

    private func loadSavedData() {
        Task { @MainActor in
            if let savedDetails = await storage.load() {
                self.name = savedDetails.name
                self.birthDate = savedDetails.birthDate
                self.birthTime = savedDetails.birthTime
                self.location = savedDetails.location
                self.timeZone = savedDetails.timeZone
                self.coordinate = savedDetails.coordinate
                self.hasSavedData = true
            }
        }
    }

    func clearData() {
        Task {
            await storage.clear()
            await MainActor.run {
                self.name = ""
                self.birthDate = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
                self.birthTime = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
                self.location = ""
                self.timeZone = .current
                self.coordinate = nil
                self.hasSavedData = false
            }
        }
    }

    // MARK: - Derived Values

    var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 1900
        let minDate = calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)

        components.year = 2100
        let maxDate = calendar.date(from: components) ?? Date.distantFuture

        return minDate...maxDate
    }

    func makeDetails() -> BirthDetails {
        BirthDetails(
            name: name,
            birthDate: birthDate,
            birthTime: birthTime,
            location: location,
            timeZone: timeZone,
            coordinate: coordinate
        )
    }

    func updateLocation(with suggestion: LocationSuggestion) {
        location = suggestion.displayName
        timeZone = suggestion.timeZone ?? .current
        coordinate = suggestion.coordinate
    }

    var locationDisplay: String {
        location.isEmpty ? "Виберіть місце" : location
    }

    // MARK: - Private Helpers

    private func setupValidation() {
        Publishers.CombineLatest($location, $coordinate)
            .map { location, coordinate in
                !location.isEmpty && coordinate != nil
            }
            .assign(to: &$isValid)
    }

    private func setupAutoSave() {
        // Save data whenever any field changes (with debounce to avoid excessive saves)
        Publishers.CombineLatest4(
            $name,
            $birthDate,
            $birthTime,
            $location
        )
        .combineLatest($timeZone, $coordinate)
        .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            guard let self = self else { return }
            let details = self.makeDetails()
            Task {
                await self.storage.save(details)
                await MainActor.run {
                    self.hasSavedData = true
                }
            }
        }
        .store(in: &cancellables)
    }
}
