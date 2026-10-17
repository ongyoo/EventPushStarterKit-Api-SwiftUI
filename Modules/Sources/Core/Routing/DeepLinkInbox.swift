//
//  DeepLinkInbox.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation

/// Single mailbox for deep links coming from outside the navigation tree:
/// notification taps, Siri / App Intents, widgets, silent push...
///
/// Links posted before the UI is ready are kept and delivered as soon as
/// the app coordinator sets its handler.
///
///     DeepLinkInbox.shared.post(DeepLink("events/42"))
@MainActor
public final class DeepLinkInbox {
    /// Used by notification taps, Siri and widgets; the app coordinator reads it.
    public static let shared = DeepLinkInbox()

    private var handler: ((DeepLink) -> Bool)?
    private(set) var pending: [DeepLink] = []

    /// Separate inbox for tests.
    public init() {}

    /// Set by the root coordinator. Capture it weakly.
    public func setHandler(_ handler: @escaping (DeepLink) -> Bool) {
        self.handler = handler
        let queued = pending
        pending.removeAll()
        queued.forEach { _ = handler($0) }
    }

    /// Delivers now, or keeps the link until a handler is set (cold start).
    public func post(_ link: DeepLink) {
        guard let handler else {
            pending.append(link)
            return
        }
        _ = handler(link)
    }
}
