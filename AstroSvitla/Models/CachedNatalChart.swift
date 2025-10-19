//
//  CachedNatalChart.swift
//  AstroSvitla
//  SwiftData model for persisted natal charts and metadata.

import CoreLocation
import Foundation
import SwiftData

@Model
final class CachedNatalChart {
    @Attribute(.unique) var id: UUID
    var birthDataJSON: Data
    var planetsJSON: Data
    var housesJSON: Data
    var aspectsJSON: Data
    var ascendant: Double
    var midheaven: Double
    var houseSystem: String
    var generatedAt: Date
    var imageFileID: String?
    var imageFormat: String?

    init(
        id: UUID = UUID(),
        birthDataJSON: Data = Data(),
        planetsJSON: Data = Data(),
        housesJSON: Data = Data(),
        aspectsJSON: Data = Data(),
        ascendant: Double = 0,
        midheaven: Double = 0,
        houseSystem: String = "placidus",
        generatedAt: Date = Date(),
        imageFileID: String? = nil,
        imageFormat: String? = nil
    ) {
        self.id = id
        self.birthDataJSON = birthDataJSON
        self.planetsJSON = planetsJSON
        self.housesJSON = housesJSON
        self.aspectsJSON = aspectsJSON
        self.ascendant = ascendant
        self.midheaven = midheaven
        self.houseSystem = houseSystem
        self.generatedAt = generatedAt
        self.imageFileID = imageFileID
        self.imageFormat = imageFormat
    }
}

// MARK: - Codable Helpers

extension CachedNatalChart {

    struct CachedBirthDetails: Codable, Equatable {
        let name: String
        let birthDate: Date
        let birthTime: Date
        let location: String
        let timeZoneIdentifier: String
        let latitude: Double?
        let longitude: Double?

        init(from details: BirthDetails) {
            name = details.name
            birthDate = details.birthDate
            birthTime = details.birthTime
            location = details.location
            timeZoneIdentifier = details.timeZone.identifier
            latitude = details.coordinate?.latitude
            longitude = details.coordinate?.longitude
        }

        func makeBirthDetails() -> BirthDetails {
            let timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .current
            let coordinate: CLLocationCoordinate2D?
            if let latitude, let longitude {
                coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            } else {
                coordinate = nil
            }

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

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()

    func apply(
        chart: NatalChart,
        birthDetails: BirthDetails,
        houseSystem: String,
        imageFileID: String?,
        imageFormat: String?
    ) throws {
        let detailsPayload = CachedBirthDetails(from: birthDetails)
        birthDataJSON = try Self.encoder.encode(detailsPayload)
        planetsJSON = try Self.encoder.encode(chart.planets)
        housesJSON = try Self.encoder.encode(chart.houses)
        aspectsJSON = try Self.encoder.encode(chart.aspects)
        ascendant = chart.ascendant
        midheaven = chart.midheaven
        self.houseSystem = houseSystem
        generatedAt = chart.calculatedAt
        self.imageFileID = imageFileID
        self.imageFormat = imageFormat
    }

    func cachedBirthDetails() throws -> CachedBirthDetails {
        try Self.decoder.decode(CachedBirthDetails.self, from: birthDataJSON)
    }

    func matches(_ birthDetails: BirthDetails) -> Bool {
        guard let cached = try? cachedBirthDetails() else {
            return false
        }

        let timeZoneIdentifier = birthDetails.timeZone.identifier
        let coordinatesMatch: Bool

        switch (cached.latitude, cached.longitude, birthDetails.coordinate) {
        case let (.some(lat), .some(lon), .some(coordinate)):
            coordinatesMatch = abs(lat - coordinate.latitude) < 0.0001 &&
                abs(lon - coordinate.longitude) < 0.0001
        case (.none, .none, .none):
            coordinatesMatch = true
        default:
            coordinatesMatch = false
        }

        // Compare dates and times with second-level precision (ignore milliseconds)
        let calendar = Calendar.current
        let cachedDateComponents = calendar.dateComponents([.year, .month, .day], from: cached.birthDate)
        let inputDateComponents = calendar.dateComponents([.year, .month, .day], from: birthDetails.birthDate)
        let cachedTimeComponents = calendar.dateComponents([.hour, .minute, .second], from: cached.birthTime)
        let inputTimeComponents = calendar.dateComponents([.hour, .minute, .second], from: birthDetails.birthTime)

        let datesMatch = cachedDateComponents.year == inputDateComponents.year &&
            cachedDateComponents.month == inputDateComponents.month &&
            cachedDateComponents.day == inputDateComponents.day

        let timesMatch = cachedTimeComponents.hour == inputTimeComponents.hour &&
            cachedTimeComponents.minute == inputTimeComponents.minute &&
            cachedTimeComponents.second == inputTimeComponents.second

        return datesMatch &&
            timesMatch &&
            cached.location.caseInsensitiveCompare(birthDetails.location) == .orderedSame &&
            cached.timeZoneIdentifier == timeZoneIdentifier &&
            coordinatesMatch
    }

    func toBirthDetails() throws -> BirthDetails {
        try cachedBirthDetails().makeBirthDetails()
    }

    func toNatalChart() throws -> NatalChart {
        let birthDetails = try toBirthDetails()
        let planets = try Self.decoder.decode([Planet].self, from: planetsJSON)
        let houses = try Self.decoder.decode([House].self, from: housesJSON)
        let aspects = try Self.decoder.decode([Aspect].self, from: aspectsJSON)
        
        // Calculate house rulers from houses and planets
        let houseRulers = houses.compactMap { house -> HouseRuler? in
            let rulingPlanet = TraditionalRulershipTable.ruler(of: house.sign)
            guard let ruler = planets.first(where: { $0.name == rulingPlanet }) else {
                return nil
            }
            return HouseRuler(
                houseNumber: house.number,
                rulingPlanet: rulingPlanet,
                rulerSign: ruler.sign,
                rulerHouse: ruler.house,
                rulerLongitude: ruler.longitude
            )
        }

        return NatalChart(
            birthDate: birthDetails.birthDate,
            birthTime: birthDetails.birthTime,
            latitude: birthDetails.coordinate?.latitude ?? 0,
            longitude: birthDetails.coordinate?.longitude ?? 0,
            locationName: birthDetails.location,
            planets: planets,
            houses: houses,
            aspects: aspects,
            houseRulers: houseRulers,
            ascendant: ascendant,
            midheaven: midheaven,
            calculatedAt: generatedAt,
            imageFileID: imageFileID,
            imageFormat: imageFormat
        )
    }
}
