import Foundation

/// Represents a significant astrological point that is not part of the traditional planet list,
/// such as the lunar nodes, Black Moon Lilith, or chart angles.
struct AstrologicalPoint: Codable, Identifiable, Sendable {

    enum PointType: String, Codable, CaseIterable, Sendable {
        case northNode = "North Node"
        case southNode = "South Node"
        case lilith = "Lilith"
        case ascendant = "Ascendant"
        case midheaven = "Midheaven"
    }

    enum ValidationError: LocalizedError {
        case invalidLongitude(Double)
        case invalidHouse(Int)

        var errorDescription: String? {
            switch self {
            case .invalidLongitude(let value):
                return "Longitude must be within 0° (inclusive) and 360° (exclusive). Received: \(value)"
            case .invalidHouse(let value):
                return "House placement must be between 1 and 12. Received: \(value)"
            }
        }
    }

    let id: UUID
    let pointType: PointType
    let longitude: Double
    let zodiacSign: ZodiacSign
    let housePlacement: Int

    init(
        id: UUID = UUID(),
        pointType: PointType,
        longitude: Double,
        housePlacement: Int
    ) throws {
        guard longitude >= 0 && longitude < 360 else {
            throw ValidationError.invalidLongitude(longitude)
        }
        guard (1...12).contains(housePlacement) else {
            throw ValidationError.invalidHouse(housePlacement)
        }

        self.id = id
        self.pointType = pointType
        self.longitude = longitude
        self.zodiacSign = ZodiacSign.from(degree: longitude)
        self.housePlacement = housePlacement
    }

    /// Normalized degree within the zodiac sign (0°-30° range).
    var degreeInSign: Double {
        let normalized = longitude.truncatingRemainder(dividingBy: 360)
        let signIndex = Double(zodiacSignIndex) * 30.0
        return normalized - signIndex
    }

    private var zodiacSignIndex: Int {
        guard let index = ZodiacSign.allCases.firstIndex(of: zodiacSign) else {
            return 0
        }
        return index
    }
}
