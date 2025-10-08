import Foundation
import CoreLocation
import SwiftData

@Model
final class BirthChart {
    @Attribute(.unique)
    var id: UUID

    var name: String

    var birthDate: Date
    var birthTime: Date
    var locationName: String
    var latitude: Double
    var longitude: Double
    var timezone: String

    var chartDataJSON: String

    var createdAt: Date
    var updatedAt: Date

    @Relationship(inverse: \User.charts)
    var user: User?

    @Relationship(deleteRule: .cascade)
    var reports: [ReportPurchase]

    init(
        id: UUID = UUID(),
        name: String,
        birthDate: Date,
        birthTime: Date,
        locationName: String,
        latitude: Double,
        longitude: Double,
        timezone: String,
        chartDataJSON: String = ""
    ) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.birthTime = birthTime
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.timezone = timezone
        self.chartDataJSON = chartDataJSON
        self.createdAt = Date()
        self.updatedAt = Date()
        self.reports = []
    }

    var birthDateTime: String {
        let date = BirthChart.dateFormatter.string(from: birthDate)
        let time = BirthChart.timeFormatter.string(from: birthTime)
        return "\(date) \(time)"
    }

    func updateChartData(_ jsonString: String) {
        chartDataJSON = jsonString
        updatedAt = Date()
    }

    func decodedNatalChart() -> NatalChart? {
        guard chartDataJSON.isEmpty == false,
              let data = chartDataJSON.data(using: .utf8) else { return nil }
        return try? BirthChart.chartDecoder.decode(NatalChart.self, from: data)
    }

    func makeBirthDetails() -> BirthDetails {
        let tz = TimeZone(identifier: timezone) ?? .current
        let coordinate = latitude == 0 && longitude == 0 ? nil : CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        return BirthDetails(
            name: name,
            birthDate: birthDate,
            birthTime: birthTime,
            location: locationName,
            timeZone: tz,
            coordinate: coordinate
        )
    }

    func encodedChartData(from chart: NatalChart) -> String? {
        guard let data = try? BirthChart.chartEncoder.encode(chart) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func encodedChartJSON(from chart: NatalChart) -> String? {
        guard let data = try? chartEncoder.encode(chart) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

private extension BirthChart {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    static let chartDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    static let chartEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}
