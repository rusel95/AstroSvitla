import Foundation
import CoreLocation

struct LocationSearchService {
    private let geocoder = CLGeocoder()

    func search(query: String) async throws -> [LocationSuggestion] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else { return [] }

        if Task.isCancelled { return [] }

        let placemarks = try await geocode(address: trimmed)

        return placemarks.compactMap { placemark in
            guard let name = placemark.name ?? placemark.locality else { return nil }

            var components: [String] = []
            if let locality = placemark.locality, locality.caseInsensitiveCompare(name) != .orderedSame {
                components.append(locality)
            } else if let subLocality = placemark.subLocality {
                components.append(subLocality)
            }
            if let administrativeArea = placemark.administrativeArea {
                components.append(administrativeArea)
            }
            if let country = placemark.country {
                components.append(country)
            }

            let subtitle = components
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.isEmpty == false }
                .joined(separator: ", ")

            return LocationSuggestion(
                title: name,
                subtitle: subtitle,
                coordinate: placemark.location?.coordinate,
                timeZone: placemark.timeZone
            )
        }
        .unique(by: \.displayName)
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
