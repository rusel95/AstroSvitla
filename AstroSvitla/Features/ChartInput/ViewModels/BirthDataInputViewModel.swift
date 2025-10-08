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

    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Init

    init(initialDetails: BirthDetails? = nil) {
        if let initialDetails {
            self.name = initialDetails.name
            self.birthDate = initialDetails.birthDate
            self.birthTime = initialDetails.birthTime
            self.location = initialDetails.location
            self.timeZone = initialDetails.timeZone
            self.coordinate = initialDetails.coordinate
        } else {
            let sample = ReportGenerationDemoData.sampleBirthDetails
            self.name = sample.name
            self.birthDate = sample.birthDate
            self.birthTime = sample.birthTime
            self.location = sample.location
            self.timeZone = sample.timeZone
            self.coordinate = sample.coordinate
        }

        setupValidation()
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
        isValid = true
    }
}
