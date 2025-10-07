@testable import AstroSvitla
import Testing

struct ZodiacSignTests {

    @Test
    func testElementAssignments() {
        #expect(ZodiacSign.aries.element == .fire)
        #expect(ZodiacSign.taurus.element == .earth)
        #expect(ZodiacSign.gemini.element == .air)
        #expect(ZodiacSign.cancer.element == .water)
    }

    @Test
    func testModalityAssignments() {
        #expect(ZodiacSign.aries.modality == .cardinal)
        #expect(ZodiacSign.leo.modality == .fixed)
        #expect(ZodiacSign.virgo.modality == .mutable)
    }

    @Test
    func testDegreeRanges() {
        #expect(ZodiacSign.aries.degreeRange.lowerBound == 0)
        #expect(ZodiacSign.aries.degreeRange.upperBound == 30)
        #expect(ZodiacSign.cancer.degreeRange.lowerBound == 90)
    }
}
