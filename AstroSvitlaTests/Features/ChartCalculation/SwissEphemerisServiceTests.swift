import Foundation
@testable import AstroSvitla
import Testing

struct SwissEphemerisServiceTests {

    private let service = SwissEphemerisService()
    private let utc = TimeZone(secondsFromGMT: 0)!

    @Test
    func testInvalidTimeZoneThrows() {
        #expect(throws: SwissEphemerisServiceError.invalidTimeZoneIdentifier("Mars/Base")) {
            _ = try service.timeZone(from: "Mars/Base")
        }
    }

    @Test
    func testLocalDateCombinesDateAndTime() throws {
        let timeZone = try service.timeZone(from: "Europe/Kyiv")
        let birthDate = makeDate(year: 1990, month: 4, day: 15, hour: 0, minute: 0, timeZone: timeZone)
        let birthTime = makeDate(year: 1990, month: 4, day: 15, hour: 14, minute: 30, timeZone: timeZone)

        let combined = try service.localDate(
            birthDate: birthDate,
            birthTime: birthTime,
            timeZone: timeZone
        )

        let expected = makeDate(year: 1990, month: 4, day: 15, hour: 14, minute: 30, timeZone: timeZone)
        #expect(abs(combined.timeIntervalSince(expected)) < 1)
    }

    @Test
    func testUTCConversionRespectsDSTOffset() throws {
        let timeZone = try service.timeZone(from: "America/New_York")
        let birthDate = makeDate(year: 2023, month: 7, day: 4, hour: 0, minute: 0, timeZone: timeZone)
        let birthTime = makeDate(year: 2023, month: 7, day: 4, hour: 10, minute: 15, timeZone: timeZone)

        let utcDate = try service.utcDate(
            birthDate: birthDate,
            birthTime: birthTime,
            timeZone: timeZone
        )

        let expectedUTC = makeDate(year: 2023, month: 7, day: 4, hour: 14, minute: 15, timeZone: utc)
        #expect(abs(utcDate.timeIntervalSince(expectedUTC)) < 1)

        let offset = try service.secondsFromGMT(
            birthDate: birthDate,
            birthTime: birthTime,
            timeZoneIdentifier: "America/New_York"
        )
        #expect(offset == -14_400)
    }

    @Test
    func testUTCConversionAcrossStandardTime() throws {
        let timeZone = try service.timeZone(from: "America/New_York")
        let birthDate = makeDate(year: 2023, month: 1, day: 15, hour: 0, minute: 0, timeZone: timeZone)
        let birthTime = makeDate(year: 2023, month: 1, day: 15, hour: 10, minute: 15, timeZone: timeZone)

        let utcDate = try service.utcDate(
            birthDate: birthDate,
            birthTime: birthTime,
            timeZone: timeZone
        )

        let expectedUTC = makeDate(year: 2023, month: 1, day: 15, hour: 15, minute: 15, timeZone: utc)
        #expect(abs(utcDate.timeIntervalSince(expectedUTC)) < 1)

        let offset = try service.secondsFromGMT(
            birthDate: birthDate,
            birthTime: birthTime,
            timeZoneIdentifier: "America/New_York"
        )
        #expect(offset == -18_000)
    }

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        timeZone: TimeZone
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0
        components.timeZone = timeZone

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        return calendar.date(from: components)!
    }
}
