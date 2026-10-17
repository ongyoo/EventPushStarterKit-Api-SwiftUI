//
//  EventActivityAttributes.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import ActivityKit
import Foundation

/// Data of the "event day" Live Activity. Shared by the app (starts/updates it)
/// and the widget extension (draws it), which links the `Domain` product.
public struct EventActivityAttributes: ActivityAttributes {
    /// Changes over time (sent with each update).
    public struct ContentState: Codable, Hashable, Sendable {
        public var status: String
        public var startsAt: Date

        /// `.init(status: "Gates open", startsAt: event.startDate)`
        public init(status: String, startsAt: Date) {
            self.status = status
            self.startsAt = startsAt
        }
    }

    /// Fixed for the activity's lifetime.
    public let eventID: String
    public let title: String
    public let venue: String

    /// Usually `EventActivityAttributes(event: event)`.
    public init(eventID: String, title: String, venue: String) {
        self.eventID = eventID
        self.title = title
        self.venue = venue
    }
}

public extension EventActivityAttributes {
    init(event: Event) {
        self.init(eventID: event.id, title: event.title, venue: event.location.name)
    }
}
