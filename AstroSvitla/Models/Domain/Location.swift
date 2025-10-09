//
//  Location.swift
//  AstroSvitla
//
//  Location information for birth data with validation
//

import Foundation

/// Location information for birth data
struct Location: Codable, Hashable, Sendable {
    let city: String
    let country: String
    let latitude: Double
    let longitude: Double

    init(city: String, country: String, latitude: Double, longitude: Double) {
        self.city = city
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
    }

    /// Validate latitude range (-90 to 90)
    var isValidLatitude: Bool {
        latitude >= -90.0 && latitude <= 90.0
    }

    /// Validate longitude range (-180 to 180)
    var isValidLongitude: Bool {
        longitude >= -180.0 && longitude <= 180.0
    }

    /// Check if location coordinates are valid
    var isValid: Bool {
        isValidLatitude && isValidLongitude
    }
}
