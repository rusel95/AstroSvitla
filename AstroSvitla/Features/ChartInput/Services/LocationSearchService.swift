import Foundation
import CoreLocation

struct LocationSearchService {
    private let geocoder = CLGeocoder()

    func search(query: String) async throws -> [LocationSuggestion] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else { return [] }

        if Task.isCancelled { return [] }

        // First, geocode the query to get coordinates
        let initialPlacemarks = try await geocode(address: trimmed)

        // Then reverse geocode with coordinates to get English names
        var suggestions: [LocationSuggestion] = []

        for placemark in initialPlacemarks {
            guard let coordinate = placemark.location?.coordinate else { continue }

            // Reverse geocode with coordinates to get English location names
            // Note: CLGeocoder returns English names when using preferredLocale in iOS 17+
            let englishPlacemark = try? await reverseGeocodeEnglish(coordinate: coordinate)

            let actualPlacemark = englishPlacemark ?? placemark

            guard let name = actualPlacemark.locality ?? actualPlacemark.name else { continue }

            var components: [String] = []

            if let administrativeArea = actualPlacemark.administrativeArea {
                components.append(administrativeArea)
            }
            if let country = actualPlacemark.country {
                components.append(country)
            }

            // Add ISO country code for API geocoding reliability
            if let isoCountryCode = actualPlacemark.isoCountryCode {
                components.append(isoCountryCode)
            }

            let subtitle = components
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.isEmpty == false }
                .joined(separator: ", ")

            suggestions.append(LocationSuggestion(
                title: name,
                subtitle: subtitle,
                coordinate: coordinate,
                timeZone: actualPlacemark.timeZone
            ))
        }

        return suggestions.unique(by: \.displayName)
    }

    private func geocode(address: String) async throws -> [CLPlacemark] {
        try await withCheckedThrowingContinuation { continuation in
            geocoder.geocodeAddressString(address) { placemarks, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: placemarks ?? [])
                }
            }
        }
    }

    private func reverseGeocodeEnglish(coordinate: CLLocationCoordinate2D) async throws -> CLPlacemark {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        // iOS 17+ supports preferredLocale for English names
        if #available(iOS 17.0, *) {
            let placemarks = try await geocoder.reverseGeocodeLocation(
                location,
                preferredLocale: Locale(identifier: "en_US")
            )
            guard let placemark = placemarks.first else {
                throw NSError(domain: "LocationSearchService", code: -1)
            }
            return placemark
        } else {
            // For older iOS versions, use standard reverse geocoding
            // Names may still be localized, but at least we tried
            return try await withCheckedThrowingContinuation { continuation in
                geocoder.reverseGeocodeLocation(location) { placemarks, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let placemark = placemarks?.first {
                        continuation.resume(returning: placemark)
                    } else {
                        continuation.resume(throwing: NSError(domain: "LocationSearchService", code: -1))
                    }
                }
            }
        }
    }
}

private extension Array {
    func unique<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen: Set<T> = []
        return reduce(into: [Element]()) { result, element in
            let key = element[keyPath: keyPath]
            guard seen.contains(key) == false else { return }
            seen.insert(key)
            result.append(element)
        }
    }
}
