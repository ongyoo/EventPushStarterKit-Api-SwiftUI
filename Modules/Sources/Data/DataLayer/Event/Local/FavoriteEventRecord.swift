//
//  FavoriteEventRecord.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation
import SwiftData

/// SwiftData row for a favorite event. Stays inside Domain: features only
/// see the `FavoriteEvent` value type.
@Model
public final class FavoriteEventRecord {
    @Attribute(.unique) public var eventID: String
    public var title: String
    public var savedAt: Date

    init(eventID: String, title: String, savedAt: Date = .now) {
        self.eventID = eventID
        self.title = title
        self.savedAt = savedAt
    }
}
