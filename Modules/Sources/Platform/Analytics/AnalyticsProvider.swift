//
//  AnalyticsProvider.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Core
import Foundation

/// One analytics destination (an SDK adapter). Events arrive already
/// sanitized and only when the user agreed.
///
/// Add an SDK = one adapter file here (see Templates/Extensions/Analytics)
/// + one line in `AppAssembly`. Nothing else in the app changes.
public protocol AnalyticsProvider: Sendable {
    func send(_ event: AnalyticsEvent)
    func setUserID(_ id: String?)
    func setUserProperty(_ value: String?, forName name: String)
    /// Called when the user withdraws consent: clear ids and queued data.
    func reset()
}

public extension AnalyticsProvider {
    func setUserID(_ id: String?) {}
    func setUserProperty(_ value: String?, forName name: String) {}
    func reset() {}
}

/// Prints events to the console (Xcode and Console.app, category "analytics").
/// Used in Debug builds to see what would be sent.
public struct ConsoleAnalyticsProvider: AnalyticsProvider {
    public init() {}

    public func send(_ event: AnalyticsEvent) {
        let parameters = event.parameters.keys.sorted().map { "\($0)=\(event.parameters[$0]?.description ?? "")" }
        Log.analytics.debug("📊 \(event.name, privacy: .public) \(parameters.joined(separator: " "), privacy: .public)")
    }

    public func setUserID(_ id: String?) {
        Log.analytics.debug("📊 user_id=\(id ?? "nil", privacy: .private)")
    }

    public func setUserProperty(_ value: String?, forName name: String) {
        Log.analytics.debug("📊 property \(name, privacy: .public)=\(value ?? "nil", privacy: .public)")
    }
}
