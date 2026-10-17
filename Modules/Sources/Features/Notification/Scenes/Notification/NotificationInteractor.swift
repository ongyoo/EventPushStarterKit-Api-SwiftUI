//
//  NotificationInteractor.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Domain
import Foundation

/// Notifications are local samples for now. Replace with a repository
/// (e.g. `NotificationRepository` in a Notification domain) when the API exists.
final class NotificationInteractor: NotificationInteracting {
    private let now: @Sendable () -> Date

    init(now: @escaping @Sendable () -> Date = { .now }) {
        self.now = now
    }

    func fetchItems() async throws -> [NotificationItem] {
        let now = now()
        func daysAgo(_ days: Double) -> Date { now.addingTimeInterval(-86_400 * days) }
        return [
            NotificationItem(id: "n1", title: "Event reminder", body: "King's Cup kicks off tomorrow at 18:00.", date: now, kind: .reminder, eventID: "1"),
            NotificationItem(id: "n2", title: "New event", body: "UEFA Champions League Final is now available.", date: daysAgo(1), kind: .newEvent, eventID: "2"),
            NotificationItem(id: "n3", title: "Event update", body: "The venue for Formula 1 Monaco has changed.", date: daysAgo(3), kind: .update, eventID: "6"),
            NotificationItem(id: "n4", title: "Tickets available", body: "Tickets for New York Marathon are on sale.", date: daysAgo(6), kind: .ticketAvailable, eventID: "7"),
            NotificationItem(id: "n5", title: "Event cancelled", body: "Sorry, Summer Music Festival has been cancelled.", date: daysAgo(10), kind: .cancelled, eventID: nil),
        ]
    }
}
