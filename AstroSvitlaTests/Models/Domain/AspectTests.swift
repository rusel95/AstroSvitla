@testable import AstroSvitla
import Testing

struct AspectTests {

    @Test
    func testAspectTypeAngles() {
        #expect(AspectType.conjunction.angle == 0)
        #expect(AspectType.opposition.angle == 180)
        #expect(AspectType.trine.angle == 120)
        #expect(AspectType.square.angle == 90)
        #expect(AspectType.sextile.angle == 60)
    }

    @Test
    func testAspectTypeMaxOrbs() {
        #expect(AspectType.conjunction.maxOrb == 8.0)
        #expect(AspectType.trine.maxOrb == 7.0)
        #expect(AspectType.sextile.maxOrb == 6.0)
    }

    @Test
    func testAspectOrbClamping() {
        let aspect = Aspect(
            planet1: .sun,
            planet2: .moon,
            type: .sextile,
            orb: 9.0,
            isApplying: true
        )

        #expect(aspect.orb == AspectType.sextile.maxOrb)
    }
}
