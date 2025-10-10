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

    /// Convert to query parameters for Prokerala API
    func toQueryParameters() -> [URLQueryItem] {
        // Combine date and time into ISO 8601 format with timezone
        let calendar = Calendar.current
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
        let coordinates = "\(birthDetails.coordinate?.latitude ?? 0),\(birthDetails.coordinate?.longitude ?? 0)"

        return [
            URLQueryItem(name: "datetime", value: datetimeString),
            URLQueryItem(name: "coordinates", value: coordinates),
            URLQueryItem(name: "ayanamsa", value: "1"), // 1 = Tropical/Western
            URLQueryItem(name: "house_system", value: houseSystem),
            URLQueryItem(name: "la", value: "en") // Language
        ]
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
