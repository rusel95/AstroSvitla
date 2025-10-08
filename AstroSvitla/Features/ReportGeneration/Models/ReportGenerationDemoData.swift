import Foundation
import CoreLocation

enum ReportGenerationDemoData {

    static let sampleBirthDetails: BirthDetails = {
        let timeZone = TimeZone(identifier: "Europe/Kyiv") ?? .current
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let birthDateComponents = DateComponents(timeZone: timeZone, year: 1993, month: 6, day: 21)
        let birthTimeComponents = DateComponents(timeZone: timeZone, hour: 8, minute: 45)

        let birthDate = calendar.date(from: birthDateComponents) ?? Date()
        let birthTime = calendar.date(from: birthTimeComponents) ?? Date()

        let coordinate = CLLocationCoordinate2D(latitude: 50.4501, longitude: 30.5234)

        return BirthDetails(
            name: "Demo Наталія",
            birthDate: birthDate,
            birthTime: birthTime,
            location: "Київ, Україна",
            timeZone: timeZone,
            coordinate: coordinate
        )
    }()
}
