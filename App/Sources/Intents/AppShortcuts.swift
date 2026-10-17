//
//  AppShortcuts.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

#if FEATURE_SIRI
import AppIntents
import App

// Siri, Shortcuts, Spotlight and Apple Intelligence all use App Intents.
// Each intent just opens a deep link, so it reuses the normal navigation code.
// Compiled only when FEATURE_SIRI = YES (Config/Features.xcconfig).

struct OpenNotificationsIntent: AppIntent {
    static var title: LocalizedStringResource { "Open notifications" }
    static var description: IntentDescription { IntentDescription("Shows your latest notifications.") }
    static var openAppWhenRun: Bool { true }

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLinks.open(path: "inbox")
        return .result()
    }
}

struct OpenEventsIntent: AppIntent {
    static var title: LocalizedStringResource { "Browse events" }
    static var description: IntentDescription { IntentDescription("Shows upcoming events.") }
    static var openAppWhenRun: Bool { true }

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLinks.open(path: "events")
        return .result()
    }
}

struct OpenEventIntent: AppIntent {
    static var title: LocalizedStringResource { "Open event" }
    static var description: IntentDescription { IntentDescription("Opens one event by its ID.") }
    static var openAppWhenRun: Bool { true }

    @Parameter(title: "Event ID")
    var eventID: String

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLinks.open(path: "events/\(eventID)")
        return .result()
    }
}

/// Phrases Siri understands without any setup by the user.
struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenEventsIntent(),
            phrases: ["Show events in \(.applicationName)", "Browse \(.applicationName)"],
            shortTitle: "Events",
            systemImageName: "calendar"
        )
        AppShortcut(
            intent: OpenNotificationsIntent(),
            phrases: ["Show my \(.applicationName) notifications"],
            shortTitle: "Notifications",
            systemImageName: "bell"
        )
    }
}
#endif
