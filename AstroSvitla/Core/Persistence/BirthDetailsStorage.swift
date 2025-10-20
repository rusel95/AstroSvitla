import Foundation
import CoreLocation

/// Handles persistence of birth details using UserDefaults
actor BirthDetailsStorage {

    static let shared = BirthDetailsStorage()

    private let userDefaults = UserDefaults.standard
    private let storageKey = "lastBirthDetails"

    private init() {}

    /// Save birth details to persistent storage
    func save(_ details: BirthDetails) {
        let dto = BirthDetailsDTO(from: details)
        if let encoded = try? JSONEncoder().encode(dto) {
            userDefaults.set(encoded, forKey: storageKey)
        }
    }

    /// Load the last saved birth details from storage
    func load() -> BirthDetails? {
        guard let data = userDefaults.data(forKey: storageKey),
              let dto = try? JSONDecoder().decode(BirthDetailsDTO.self, from: data) else {
            return nil
        }
        return dto.toBirthDetails()
    }

    /// Clear saved birth details
    func clear() {
        userDefaults.removeObject(forKey: storageKey)
    }
}

// MARK: - Data Transfer Object

/// Codable DTO for BirthDetails since CLLocationCoordinate2D is not Codable
private struct BirthDetailsDTO: Codable {
    let name: String
    let birthDate: Date
    let birthTime: Date
    let location: String
    let timeZoneIdentifier: String
    let latitude: Double?
    let longitude: Double?

    nonisolated init(from details: BirthDetails) {
        self.name = details.name
        self.birthDate = details.birthDate
        self.birthTime = details.birthTime
        self.location = details.location
        self.timeZoneIdentifier = details.timeZone.identifier
        self.latitude = details.coordinate?.latitude
        self.longitude = details.coordinate?.longitude
    }

    nonisolated func toBirthDetails() -> BirthDetails {
        let coordinate: CLLocationCoordinate2D?
        if let lat = latitude, let lon = longitude {
            coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        } else {
            coordinate = nil
        }

        let timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .current

        return BirthDetails(
            name: name,
            birthDate: birthDate,
            birthTime: birthTime,
            location: location,
            timeZone: timeZone,
            coordinate: coordinate
        )
    }
}
