//
//  Date+Formatting.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation

// Uses `FormatStyle` (thread-safe and cached by the system)
// instead of creating a new `DateFormatter` on every call.
// Uses the in-app language (`AppLocale`), so formats switch with it.
public extension Date {
    /// "Jun 30"
    var monthDayText: String { formatted(.dateTime.month(.abbreviated).day().locale(AppLocale.current)) }

    /// "Jun"
    var monthText: String { formatted(.dateTime.month(.abbreviated).locale(AppLocale.current)) }

    /// "30"
    var dayText: String { formatted(.dateTime.day().locale(AppLocale.current)) }

    /// "in 3 days", "2 hr. ago"
    var relativeText: String { formatted(.relative(presentation: .named, unitsStyle: .abbreviated).locale(AppLocale.current)) }

    /// Parses "2025-09-24T10:00:00Z".
    init?(iso8601 string: String) {
        guard let date = try? Date(string, strategy: .iso8601) else { return nil }
        self = date
    }
}
