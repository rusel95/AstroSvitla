import Foundation
import CoreLocation

struct LocationSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D?
    let timeZone: TimeZone?

    var displayName: String {
        if subtitle.isEmpty {
            return title
        }
        return "\(title), \(subtitle)"
    }
}
