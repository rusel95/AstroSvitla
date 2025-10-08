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
        birthTime.formatted(.dateTime
            .hour()
            .minute()
        )
    }

    var formattedLocation: String {
        location.isEmpty ? "—" : location
    }

    var isEmpty: Bool {
        location.isEmpty
    }
}
