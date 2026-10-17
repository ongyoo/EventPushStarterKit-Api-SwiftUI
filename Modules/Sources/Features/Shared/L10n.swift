//
//  L10n.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Domain
import Foundation

/// Every user-facing text of the Features module. Keys live in
/// Resources/Localizable.xcstrings (edit in Xcode or with scripts/strings.py).
///
/// Values are read on each access, so after a language change the rebuilt
/// screens show the new language immediately.
///
/// Public only for the App layer (tab titles, notification texts).
@MainActor
public enum L10n {
    @MainActor
    public enum Tab {
        public static var home: String { tr("tab.home") }
        public static var inbox: String { tr("tab.inbox") }
        public static var settings: String { tr("tab.settings") }
        public static var camera: String { tr("tab.camera") }
    }

    @MainActor
    enum Home {
        static var title: String { tr("home.title") }
        static var location: String { tr("home.location") }
        static var search: String { tr("home.search") }
        static var clearSearch: String { tr("home.search.clear") }
        static var notifications: String { tr("home.notifications") }
        static var popular: String { tr("home.popular") }
        static var upcoming: String { tr("home.upcoming") }
        static var seeAll: String { tr("home.seeAll") }
        static func seeAll(count: Int) -> String { tr("home.seeAllCount", count) }
        static var emptyTitle: String { tr("home.empty.title") }
        static var emptyMessage: String { tr("home.empty.message") }
    }

    @MainActor
    public enum Event {
        public static var title: String { tr("event.title") }
        static var date: String { tr("event.date") }
        static var location: String { tr("event.location") }
        static var price: String { tr("event.price") }
        static var free: String { tr("event.free") }
        static var organizer: String { tr("event.organizer") }
        static var about: String { tr("event.about") }
        static var organizerTitle: String { tr("organizer.title") }
        static func eventsCount(_ count: Int) -> String { tr("organizer.eventsCount", count) }
    }

    @MainActor
    enum Events {
        static var allTitle: String { tr("events.title.all") }
        static var filter: String { tr("events.filter") }
        static var emptyMessage: String { tr("events.empty.message") }
    }

    @MainActor
    enum Inbox {
        static var title: String { tr("inbox.title") }
        static var empty: String { tr("inbox.empty") }
    }

    static func category(_ category: EventCategory) -> String {
        tr("category.\(category.rawValue)")
    }

    static func permission(_ permission: Permission) -> String {
        tr("permission.\(permission.rawValue)")
    }

    static func permissionStatus(_ status: PermissionStatus) -> String {
        switch status {
        case .notDetermined: tr("permission.status.notDetermined")
        case .authorized: tr("permission.status.authorized")
        case .limited: tr("permission.status.limited")
        case .provisional: tr("permission.status.provisional")
        case .denied: tr("permission.status.denied")
        case .restricted: tr("permission.status.restricted")
        case .unavailable: tr("permission.status.unavailable")
        }
    }

    /// Raw lookup for keys not wrapped above (Settings uses many one-off keys).
    public static func tr(_ key: String) -> String {
        LocalizationManager.shared.localized(key, bundle: .module)
    }

    /// Format with arguments; plural rules from the catalog apply ("%lld events").
    public static func tr(_ key: String, _ arguments: any CVarArg...) -> String {
        String(format: tr(key), locale: AppLocale.current, arguments: arguments)
    }
}
