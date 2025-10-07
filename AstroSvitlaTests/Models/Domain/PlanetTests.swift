import Foundation
@testable import AstroSvitla
import Testing

struct PlanetTests {

    @Test
    func testPlanetInitialization() {
        let planet = Planet(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: .moon,
            longitude: 45.0,
            latitude: -0.5,
            sign: .taurus,
            house: 2,
            isRetrograde: true,
            speed: -0.98
        )

        #expect(planet.name == .moon)
        #expect(planet.sign == .taurus)
        #expect(planet.house == 2)
        #expect(planet.isRetrograde)
        #expect(planet.speed == -0.98)
    }
}
