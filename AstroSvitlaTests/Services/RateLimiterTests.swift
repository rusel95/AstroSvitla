import Foundation
import Testing
@testable import AstroSvitla

struct RateLimiterTests {

    // MARK: - Helpers

    private final class TestClock: RateLimiterClock {
        var currentDate: Date

        init(currentDate: Date) {
            self.currentDate = currentDate
        }

        var now: Date { currentDate }
    }

    private func makeUserDefaultsSuite() -> (defaults: UserDefaults, suiteName: String) {
        let suiteName = "com.astrosvitla.tests.rateLimiter.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Unable to create UserDefaults suite: \(suiteName)")
        }
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }

    // MARK: - Tests

    @Test("Allows requests within the sliding window limit")
    func testAllowsRequestsWithinWindow() throws {
        let start = Date(timeIntervalSince1970: 0)
        let clock = TestClock(currentDate: start)
        let (defaults, suiteName) = makeUserDefaultsSuite()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let limiter = RateLimiter(userDefaults: defaults, clock: clock)

        for index in 0..<5 {
            clock.currentDate = start.addingTimeInterval(Double(index) * 10)
            let result = limiter.canMakeRequest()
            #expect(result.allowed)
            #expect(result.retryAfter == nil)
            limiter.recordRequest()
        }
    }

    @Test("Blocks requests when limit exceeded and provides retry delay")
    func testBlocksRequestsWhenLimitExceeded() throws {
        let start = Date(timeIntervalSince1970: 0)
        let clock = TestClock(currentDate: start)
        let (defaults, suiteName) = makeUserDefaultsSuite()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let limiter = RateLimiter(userDefaults: defaults, clock: clock)

        for index in 0..<5 {
            clock.currentDate = start.addingTimeInterval(Double(index) * 10)
            #expect(limiter.canMakeRequest().allowed)
            limiter.recordRequest()
        }

        clock.currentDate = start.addingTimeInterval(50)
        let blocked = limiter.canMakeRequest()
        #expect(blocked.allowed == false)
        #expect(blocked.retryAfter != nil)
        if let retryAfter = blocked.retryAfter {
            #expect(abs(retryAfter - 10) < 0.001)
        }

        clock.currentDate = start.addingTimeInterval(61)
        let afterCooldown = limiter.canMakeRequest()
        #expect(afterCooldown.allowed)
    }

    @Test("Tracks monthly API credit usage and resets each month")
    func testMonthlyUsageTracking() throws {
        var components = DateComponents(
            calendar: Calendar(identifier: .gregorian),
            timeZone: TimeZone(secondsFromGMT: 0),
            year: 2025,
            month: 10,
            day: 1,
            hour: 12
        )
        guard let october = components.date else {
            Issue.record("Failed to build test start date")
            return
        }

        let clock = TestClock(currentDate: october)
        let (defaults, suiteName) = makeUserDefaultsSuite()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let limiter = RateLimiter(userDefaults: defaults, clock: clock)

        for dayOffset in 0..<3 {
            components.day = 1 + dayOffset
            if let date = components.date {
                clock.currentDate = date
                limiter.recordRequest()
            }
        }

        var usage = limiter.monthlyUsage
        #expect(usage.requestCount == 3)
        #expect(usage.estimatedCharts == 2)
        #expect(usage.creditsConsumed == 3)

        components.month = 11
        components.day = 2
        guard let november = components.date else {
            Issue.record("Failed to build next month date")
            return
        }

        clock.currentDate = november
        limiter.recordRequest()

        usage = limiter.monthlyUsage
        #expect(usage.requestCount == 1)
        #expect(usage.estimatedCharts == 1)
        #expect(usage.creditsConsumed == 1)
    }
}
