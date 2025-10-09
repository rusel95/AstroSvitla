//
//  RateLimiter.swift
//  AstroSvitla
//
//  Client-side rate limiter for Prokerala API usage.
//  Enforces the 5 requests per minute window and tracks monthly credits.
//

import Foundation

protocol RateLimiterClock {
    var now: Date { get }
}

struct SystemRateLimiterClock: RateLimiterClock {
    var now: Date { Date() }
}

struct RateLimiterMonthlyUsage: Sendable {
    let requestCount: Int
    let estimatedCharts: Int
    let creditsConsumed: Int
}

final class RateLimiter {

    // MARK: - Constants

    private enum Constants {
        static let timestampsKey = "com.astrosvitla.rateLimiter.timestamps"
        static let monthTokenKey = "com.astrosvitla.rateLimiter.monthToken"
        static let monthlyRequestCountKey = "com.astrosvitla.rateLimiter.monthlyRequestCount"
    }

    // MARK: - Properties

    private let userDefaults: UserDefaults
    private let clock: RateLimiterClock
    private let maxRequests: Int
    private let windowInterval: TimeInterval
    private let requestsPerChart: Int
    private let queue = DispatchQueue(label: "com.astrosvitla.services.RateLimiter")
    private var calendar: Calendar

    // MARK: - Initialization

    init(
        userDefaults: UserDefaults = .standard,
        clock: RateLimiterClock = SystemRateLimiterClock(),
        maxRequestsPerWindow: Int = 5,
        windowInterval: TimeInterval = 60,
        requestsPerChart: Int = 2
    ) {
        self.userDefaults = userDefaults
        self.clock = clock
        self.maxRequests = max(1, maxRequestsPerWindow)
        self.windowInterval = max(1, windowInterval)
        self.requestsPerChart = max(1, requestsPerChart)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        self.calendar = calendar

        queue.sync {
            let now = clock.now
            resetMonthlyUsageIfNeeded(now: now)
            let pruned = prune(loadTimestamps(), now: now)
            saveTimestamps(pruned)
        }
    }

    // MARK: - Public API

    func canMakeRequest() -> (allowed: Bool, retryAfter: TimeInterval?) {
        queue.sync {
            let now = clock.now
            var timestamps = prune(loadTimestamps(), now: now)
            saveTimestamps(timestamps)
            resetMonthlyUsageIfNeeded(now: now)

            guard timestamps.count >= maxRequests else {
                return (true, nil)
            }

            guard let oldest = timestamps.first else {
                return (true, nil)
            }

            let earliestNext = oldest + windowInterval
            let nowInterval = now.timeIntervalSince1970
            let retryAfter = max(earliestNext - nowInterval, 0)
            return (false, retryAfter)
        }
    }

    func recordRequest() {
        queue.sync {
            let now = clock.now
            var timestamps = prune(loadTimestamps(), now: now)
            timestamps.append(now.timeIntervalSince1970)
            saveTimestamps(timestamps)

            resetMonthlyUsageIfNeeded(now: now)
            let currentCount = userDefaults.integer(forKey: Constants.monthlyRequestCountKey)
            userDefaults.set(currentCount + 1, forKey: Constants.monthlyRequestCountKey)
        }
    }

    var monthlyUsage: RateLimiterMonthlyUsage {
        queue.sync {
            let now = clock.now
            resetMonthlyUsageIfNeeded(now: now)
            let requestCount = userDefaults.integer(forKey: Constants.monthlyRequestCountKey)
            let estimatedCharts = Int(ceil(Double(requestCount) / Double(requestsPerChart)))
            return RateLimiterMonthlyUsage(
                requestCount: requestCount,
                estimatedCharts: estimatedCharts,
                creditsConsumed: requestCount
            )
        }
    }

    // MARK: - Persistence Helpers

    private func loadTimestamps() -> [TimeInterval] {
        userDefaults.array(forKey: Constants.timestampsKey) as? [TimeInterval] ?? []
    }

    private func saveTimestamps(_ timestamps: [TimeInterval]) {
        userDefaults.set(timestamps, forKey: Constants.timestampsKey)
    }

    private func prune(_ timestamps: [TimeInterval], now: Date) -> [TimeInterval] {
        let cutoff = now.timeIntervalSince1970 - windowInterval
        return timestamps.filter { $0 >= cutoff }
            .sorted()
    }

    // MARK: - Monthly Tracking

    private func resetMonthlyUsageIfNeeded(now: Date) {
        let currentToken = monthIdentifier(for: now)
        let storedToken = userDefaults.string(forKey: Constants.monthTokenKey)
        if storedToken != currentToken {
            userDefaults.set(currentToken, forKey: Constants.monthTokenKey)
            userDefaults.set(0, forKey: Constants.monthlyRequestCountKey)
        }
    }

    private func monthIdentifier(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let year = components.year, let month = components.month else {
            return UUID().uuidString
        }
        return String(format: "%04d-%02d", year, month)
    }
}
