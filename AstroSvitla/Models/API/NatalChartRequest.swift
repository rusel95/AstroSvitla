//
//  NatalChartRequest.swift
//  AstroSvitla
//
//  Request model for Prokerala API natal chart generation
//

import Foundation
import CoreLocation

struct NatalChartRequest {
    let birthDetails: BirthDetails
    let houseSystem: String
    let imageFormat: String
    let chartSize: Int

    init(
        birthDetails: BirthDetails,
        houseSystem: String = "placidus",
        imageFormat: String = "svg",
        chartSize: Int = 600
    ) {
        self.birthDetails = birthDetails
        self.houseSystem = houseSystem
        self.imageFormat = imageFormat
        self.chartSize = chartSize
    }

    struct QueryParameter: Sendable {
        let name: String
        let value: String
    }

    /// Convert to query parameters for Prokerala API
    func toQueryParameters() -> [QueryParameter] {
        // Combine date and time into ISO 8601 format with timezone
        let calendar = Calendar(identifier: .gregorian)
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: birthDetails.birthDate)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: birthDetails.birthTime)

        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        dateComponents.second = timeComponents.second ?? 0
        dateComponents.timeZone = birthDetails.timeZone

        guard let combinedDateTime = calendar.date(from: dateComponents) else {
            return []
        }

        // Format datetime as ISO 8601 with timezone
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = birthDetails.timeZone
        let datetimeString = formatter.string(from: combinedDateTime)

        // Format coordinates as "lat,lon"
        let latitude = birthDetails.coordinate?.latitude ?? 0
        let longitude = birthDetails.coordinate?.longitude ?? 0
        let coordinates = String(format: "%.6f,%.6f", latitude, longitude)

        var parameters: [QueryParameter] = [
            .init(name: "profile[datetime]", value: datetimeString),
            .init(name: "profile[coordinates]", value: coordinates),
            .init(name: "settings[ayanamsa]", value: "1"), // 1 = Tropical/Western
            .init(name: "settings[house_system]", value: houseSystem),
            .init(name: "settings[language]", value: "en")
        ]

        // Include timezone offset minutes for clarity if API expects it
        let timezoneSeconds = birthDetails.timeZone.secondsFromGMT(for: combinedDateTime)
        let hours = timezoneSeconds / 3600
        let minutes = abs(timezoneSeconds / 60) % 60
        let timezoneString = String(format: "%+03d:%02d", hours, minutes)
        parameters.append(.init(name: "profile[timezone]", value: timezoneString))

        if birthDetails.location.isEmpty == false {
            parameters.append(.init(name: "profile[place]", value: birthDetails.location))
        }

        return parameters
    }


    /// Convert to request body for chart data endpoint (legacy)
    func toChartDataBody() -> [String: Any] {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: birthDetails.birthDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: birthDetails.birthTime)

        let timezoneOffset = Double(birthDetails.timeZone.secondsFromGMT()) / 3600.0

        return [
            "day": dateComponents.day ?? 1,
            "month": dateComponents.month ?? 1,
            "year": dateComponents.year ?? 2000,
            "hour": timeComponents.hour ?? 12,
            "min": timeComponents.minute ?? 0,
            "lat": birthDetails.coordinate?.latitude ?? 0,
            "lon": birthDetails.coordinate?.longitude ?? 0,
            "tzone": timezoneOffset,
            "house_type": houseSystem
        ]
    }

    /// Convert to request body for chart image endpoint (legacy)
    func toChartImageBody() -> [String: Any] {
        var body = toChartDataBody()
        body["image_type"] = imageFormat
        body["chart_size"] = chartSize
        return body
    }
}
