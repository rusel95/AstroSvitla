import Foundation
@testable import AstroSvitla
import Testing

struct NatalChartTests {

    @Test
    func testSerializationRoundTrip() throws {
        let planet = Planet(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: .sun,
            longitude: 123.45,
            latitude: 0.12,
            sign: .sagittarius,
            house: 9,
            isRetrograde: false,
            speed: 1.01
        )

        let house = House(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
            number: 1,
            cusp: 21.5,
            sign: .aries
        )

        let aspect = Aspect(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!,
            planet1: .sun,
            planet2: .moon,
            type: .trine,
            orb: 1.5,
            isApplying: true
        )

        let chart = NatalChart(
            birthDate: ISO8601DateFormatter().date(from: "1990-04-15T00:00:00Z")!,
            birthTime: ISO8601DateFormatter().date(from: "1990-04-15T14:30:00Z")!,
            latitude: 50.4501,
            longitude: 30.5234,
            locationName: "Kyiv, Ukraine",
            planets: [planet],
            houses: [house],
            aspects: [aspect],
            houseRulers: [],
            ascendant: 18.3,
            midheaven: 12.7,
            calculatedAt: Date()
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(chart)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(NatalChart.self, from: data)

        #expect(decoded.planets.count == 1)
        #expect(decoded.houses.count == 1)
        #expect(decoded.aspects.count == 1)
        #expect(decoded.planets.first?.sign == .sagittarius)
        #expect(decoded.houses.first?.sign == .aries)
        #expect(decoded.aspects.first?.type == .trine)
    }
}
