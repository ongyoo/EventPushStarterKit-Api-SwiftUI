//
//  Log.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import OSLog

/// One logger per concern. View logs in Console.app filtered by subsystem.
///
///     Log.network.debug("GET \(url)")
///     Log.memory.fault("Leak: \(name)")
public enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "app"

    /// General app events: `Log.app.info("Configured")`.
    public static let app = Logger(subsystem: subsystem, category: "app")
    /// Requests / responses (Debug only by `NetworkLogger`).
    public static let network = Logger(subsystem: subsystem, category: "network")
    /// Coordinator start / finish and deep links.
    public static let navigation = Logger(subsystem: subsystem, category: "navigation")
    /// Leak warnings from `LeakDetector`.
    public static let memory = Logger(subsystem: subsystem, category: "memory")
    /// Analytics events (console provider) and dropped parameters.
    public static let analytics = Logger(subsystem: subsystem, category: "analytics")
}
