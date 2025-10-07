import Foundation

struct NatalChart: Codable, Sendable {
    let birthDate: Date
    let birthTime: Date
    let latitude: Double
    let longitude: Double
    let locationName: String

    let planets: [Planet]
    let houses: [House]
    let aspects: [Aspect]

    let ascendant: Double
    let midheaven: Double

    var calculatedAt: Date
}
