//
//  AnalyticsEvents.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Core
import Domain

/// Every business event the Features module sends, in one place: the
/// analytics team reads this file as the tracking plan.
///
/// Rules: snake_case names, ids and categories only (never names, emails,
/// search text), past tense for things that happened.
/// Screen views are automatic (`Navigator`), don't add them here.
extension AnalyticsEvent {
    /// Where an event was opened from.
    enum Source: String {
        case popular, upcoming, list, notification, organizer
    }

    static func eventSelected(id: String, source: Source) -> AnalyticsEvent {
        AnalyticsEvent("event_selected", ["event_id": .string(id), "source": .string(source.rawValue)])
    }

    static func categorySelected(_ category: EventCategory) -> AnalyticsEvent {
        AnalyticsEvent("category_selected", ["category": .string(category.rawValue)])
    }

    static func seeAllTapped(category: EventCategory) -> AnalyticsEvent {
        AnalyticsEvent("see_all_tapped", ["category": .string(category.rawValue)])
    }

    static func favoriteToggled(eventID: String, isFavorite: Bool) -> AnalyticsEvent {
        AnalyticsEvent("favorite_toggled", ["event_id": .string(eventID), "is_favorite": .bool(isFavorite)])
    }

    static func languageChanged(_ code: String) -> AnalyticsEvent {
        AnalyticsEvent("language_changed", ["language": .string(code)])
    }

    static func permissionRequested(_ permission: Permission, granted: Bool) -> AnalyticsEvent {
        AnalyticsEvent("permission_requested", ["permission": .string(permission.rawValue), "granted": .bool(granted)])
    }
}
