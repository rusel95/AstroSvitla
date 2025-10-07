import Foundation
import SwissEphemeris

enum SwissEphemerisServiceError: LocalizedError, Equatable {
    case invalidTimeZoneIdentifier(String)
    case invalidDateComponents

    var errorDescription: String? {
        switch self {
        case .invalidTimeZoneIdentifier(let identifier):
            return "Invalid timezone identifier: \(identifier)"
        case .invalidDateComponents:
            return "Unable to construct date from provided components."
        }
    }
}

/// Wraps shared integration points with SwissEphemeris and provides helpers that
/// normalise birth data into the formats required for astronomical calculations.
final class SwissEphemerisService {

    private static var isEphemerisInitialised = false
    private static let lock = NSLock()

    private var calendar: Calendar

    init(calendar: Calendar = Calendar(identifier: .gregorian)) {
        self.calendar = calendar
        Self.ensureEphemerisPathIsSet()
    }

    /// Ensures the ephemeris data path is configured exactly once for the process.
    private static func ensureEphemerisPathIsSet() {
        lock.lock()
        defer { lock.unlock() }

        guard isEphemerisInitialised == false else { return }
        JPLFileManager.setEphemerisPath()
        isEphemerisInitialised = true
    }

    /// Returns the `TimeZone` instance for a given identifier or throws.
    func timeZone(from identifier: String) throws -> TimeZone {
        guard let timeZone = TimeZone(identifier: identifier) else {
            throw SwissEphemerisServiceError.invalidTimeZoneIdentifier(identifier)
        }
        return timeZone
    }

    /// Combines the provided birth date and time into a single `Date` in the supplied timezone.
    func localDate(
        birthDate: Date,
        birthTime: Date,
        timeZoneIdentifier: String
    ) throws -> Date {
        let timeZone = try timeZone(from: timeZoneIdentifier)
        return try localDate(birthDate: birthDate, birthTime: birthTime, timeZone: timeZone)
    }

    /// Combines birth date and time in the specified timezone and returns the absolute date in UTC.
    func utcDate(
        birthDate: Date,
        birthTime: Date,
        timeZoneIdentifier: String
    ) throws -> Date {
        let timeZone = try timeZone(from: timeZoneIdentifier)
        return try utcDate(birthDate: birthDate, birthTime: birthTime, timeZone: timeZone)
    }

    /// Combines birth date and time into a single `Date` object in the given timezone.
    func localDate(
        birthDate: Date,
        birthTime: Date,
        timeZone: TimeZone
    ) throws -> Date {
        calendar.timeZone = timeZone

        var dateComponents = calendar.dateComponents([.year, .month, .day], from: birthDate)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: birthTime)
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        dateComponents.second = timeComponents.second ?? 0

        guard let combined = calendar.date(from: dateComponents) else {
            throw SwissEphemerisServiceError.invalidDateComponents
        }

        return combined
    }

    /// Converts a local birth date into UTC, respecting the timezone offset (including DST).
    func utcDate(
        birthDate: Date,
        birthTime: Date,
        timeZone: TimeZone
    ) throws -> Date {
        let local = try localDate(birthDate: birthDate, birthTime: birthTime, timeZone: timeZone)
        return local
    }

    /// Returns the timezone offset (seconds from GMT) at the provided local date.
    func secondsFromGMT(
        birthDate: Date,
        birthTime: Date,
        timeZoneIdentifier: String
    ) throws -> Int {
        let timeZone = try timeZone(from: timeZoneIdentifier)
        let local = try localDate(birthDate: birthDate, birthTime: birthTime, timeZone: timeZone)
        return timeZone.secondsFromGMT(for: local)
    }
}
