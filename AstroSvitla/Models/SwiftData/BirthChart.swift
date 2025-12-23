import Foundation
import CoreLocation
import SwiftData

// File-level encoders/decoders and helper functions to avoid @MainActor isolation issues
private let birthChartDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
}()

private let birthChartEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return encoder
}()

// File-level helper functions - these are nonisolated by default
private func decodeNatalChart(from data: Data) -> NatalChart? {
    try? birthChartDecoder.decode(NatalChart.self, from: data)
}

private func encodeNatalChart(_ chart: NatalChart) -> Data? {
    try? birthChartEncoder.encode(chart)
}

@Model
final class BirthChart {
    @Attribute(.unique)
    var id: UUID

    var chartDataJSON: String

    var createdAt: Date
    var updatedAt: Date

    @Relationship(inverse: \UserProfile.chart)
    var profile: UserProfile?

    init(
        id: UUID = UUID(),
        chartDataJSON: String = ""
    ) {
        self.id = id
        self.chartDataJSON = chartDataJSON
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    func updateChartData(_ jsonString: String) {
        chartDataJSON = jsonString
        updatedAt = Date()
    }

    func decodedNatalChart() -> NatalChart? {
        guard chartDataJSON.isEmpty == false,
              let data = chartDataJSON.data(using: .utf8) else { return nil }
        return decodeNatalChart(from: data)
    }

    func makeBirthDetails() -> BirthDetails? {
        guard let profile = profile else { return nil }
        let tz = TimeZone(identifier: profile.timezone) ?? .current
        let coordinate = profile.latitude == 0 && profile.longitude == 0 ? nil : CLLocationCoordinate2D(latitude: profile.latitude, longitude: profile.longitude)
        return BirthDetails(
            name: profile.name,
            birthDate: profile.birthDate,
            birthTime: profile.birthTime,
            location: profile.locationName,
            timeZone: tz,
            coordinate: coordinate
        )
    }

    func encodedChartData(from chart: NatalChart) -> String? {
        guard let data = encodeNatalChart(chart) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func encodedChartJSON(from chart: NatalChart) -> String? {
        guard let data = encodeNatalChart(chart) else { return nil }
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
}
