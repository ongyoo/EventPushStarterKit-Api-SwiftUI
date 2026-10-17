//
//  AppShortcuts.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

#if FEATURE_SIRI
import App
import AppIntents

// Siri, Shortcuts, Spotlight and Apple Intelligence all use App Intents.
// Each intent opens a deep link, so it reuses the normal navigation code.
// Compiled only when FEATURE_SIRI = YES (Config/Features.xcconfig).

struct OpenHomeIntent: AppIntent {
    static var title: LocalizedStringResource { "Open home" }
    static var openAppWhenRun: Bool { true }

    @MainActor
    func perform() async throws -> some IntentResult {
        AppLinks.open(path: "home")
        return .result()
    }
}

struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenHomeIntent(),
            phrases: ["Open \(.applicationName)"],
            shortTitle: "Home",
            systemImageName: "house"
        )
    }
}
#endif
