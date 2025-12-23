import Foundation
import CoreLocation

/// Handles persistence of birth details using UserDefaults
/// Uses @MainActor to avoid concurrency issues with Codable
@MainActor
final class BirthDetailsStorage {

    static let shared = BirthDetailsStorage()

    private let userDefaults = UserDefaults.standard
    private let storageKey = "lastBirthDetails"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    /// Save birth details to persistent storage
    func save(_ details: BirthDetails) {
        let dto = BirthDetailsDTO(
            name: details.name,
            birthDate: details.birthDate,
            birthTime: details.birthTime,
            location: details.location,
            timeZoneIdentifier: details.timeZone.identifier,
            latitude: details.coordinate?.latitude,
            longitude: details.coordinate?.longitude
        )
        if let encoded = try? encoder.encode(dto) {
            userDefaults.set(encoded, forKey: storageKey)
        }
    }

    /// Load the last saved birth details from storage
    func load() -> BirthDetails? {
        guard let data = userDefaults.data(forKey: storageKey),
              let dto = try? decoder.decode(BirthDetailsDTO.self, from: data) else {
            return nil
        }
        
        let coordinate: CLLocationCoordinate2D?
        if let lat = dto.latitude, let lon = dto.longitude {
            coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        } else {
            coordinate = nil
        }
        
        let timeZone = TimeZone(identifier: dto.timeZoneIdentifier) ?? .current
        
        return BirthDetails(
            name: dto.name,
            birthDate: dto.birthDate,
            birthTime: dto.birthTime,
            location: dto.location,
            timeZone: timeZone,
            coordinate: coordinate
        )
    }

    /// Clear saved birth details
    func clear() {
        userDefaults.removeObject(forKey: storageKey)
    }
}

// MARK: - Data Transfer Object

/// Pure Codable DTO for BirthDetails - no methods that cross actor boundaries
private struct BirthDetailsDTO: Codable {
    let name: String
    let birthDate: Date
    let birthTime: Date
    let location: String
    let timeZoneIdentifier: String
    let latitude: Double?
    let longitude: Double?
}
