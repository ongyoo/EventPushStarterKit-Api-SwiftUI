//
//  CivilDate.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//


#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Calendar fields of a date at a fixed UTC offset (Gregorian calendar).
///
/// Pure arithmetic: no ICU, no time zone database, identical on every
/// platform. The host app passes its current UTC offset.
public struct CivilDate: Hashable, Sendable {
    public let year: Int
    public let month: Int      // 1...12
    public let day: Int        // 1...31
    public let weekday: Int    // 0 = Sunday ... 6 = Saturday
    public let hour: Int
    public let minute: Int
    /// Days since 1970-01-01 (local), handy for "in N days".
    public let dayNumber: Int

    public init(_ date: Date, utcOffsetSeconds: Int) {
        let seconds = Int(date.timeIntervalSince1970.rounded(.down)) + utcOffsetSeconds
        let days = Self.floorDiv(seconds, 86_400)
        let secondOfDay = seconds - days * 86_400
        dayNumber = days
        hour = secondOfDay / 3_600
        minute = secondOfDay % 3_600 / 60
        weekday = ((days % 7) + 11) % 7 // 1970-01-01 was a Thursday (4)

        // Howard Hinnant's civil_from_days.
        let z = days + 719_468
        let era = Self.floorDiv(z, 146_097)
        let dayOfEra = z - era * 146_097
        let yearOfEra = (dayOfEra - dayOfEra / 1_460 + dayOfEra / 36_524 - dayOfEra / 146_096) / 365
        let dayOfYear = dayOfEra - (365 * yearOfEra + yearOfEra / 4 - yearOfEra / 100)
        let mp = (5 * dayOfYear + 2) / 153
        day = dayOfYear - (153 * mp + 2) / 5 + 1
        month = mp < 10 ? mp + 3 : mp - 9
        year = yearOfEra + era * 400 + (month <= 2 ? 1 : 0)
    }

    private static func floorDiv(_ a: Int, _ b: Int) -> Int {
        a >= 0 ? a / b : -((-a + b - 1) / b)
    }
}
