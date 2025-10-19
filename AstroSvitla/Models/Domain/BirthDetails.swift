import Foundation
import CoreLocation

struct BirthDetails: Sendable {
    let name: String
    let birthDate: Date
    let birthTime: Date
    let location: String
    let timeZone: TimeZone
    let coordinate: CLLocationCoordinate2D?

    init(
        name: String,
        birthDate: Date,
        birthTime: Date,
        location: String,
        timeZone: TimeZone = .current,
        coordinate: CLLocationCoordinate2D? = nil
    ) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.birthDate = birthDate
        self.birthTime = birthTime
        self.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
        self.timeZone = timeZone
        self.coordinate = coordinate
    }

    var displayName: String {
        name.isEmpty ? "Ваша карта" : name
    }

    var formattedBirthDate: String {
        birthDate.formatted(.dateTime
            .year()
            .month(.wide)
            .day()
        )
    }

    var formattedBirthTime: String {
        // Use 24-hour format for Ukrainian locale, respect system settings for others
        let formatter = DateFormatter()
        formatter.locale = Locale.current

        // For Ukrainian locale, always use 24-hour format (HH:mm)
        // For other locales, respect system preferences
        if Locale.current.language.languageCode?.identifier == "uk" {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.timeStyle = .short
        }

        return formatter.string(from: birthTime)
    }

    var formattedLocation: String {
        location.isEmpty ? "—" : location
    }

    var isEmpty: Bool {
        location.isEmpty
    }
}
