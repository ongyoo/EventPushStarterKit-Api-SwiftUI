//
//  NotificationModel.swift
//  EventPush
//
//  Created by Nathat Kuanthanom on 9/4/25.
//

import Foundation

struct NotificationModel: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let date: Date
    let type: NotificationType
    
    static let samples: [NotificationModel] = [
        NotificationModel(title: "Event Reminder",
                          body: "Don't forget the meeting tomorrow at 10 AM.",
                          date: Date(),
                          type: .eventReminder),
        NotificationModel(title: "New Event Added",
                          body: "UEFA Champions League Final is now available.",
                          date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                          type: .newEvent),
        NotificationModel(title: "Event Update",
                          body: "The venue for Formula 1 Monaco has changed.",
                          date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
                          type: .eventUpdate),
        NotificationModel(title: "Tickets Available",
                          body: "Tickets for NYC Marathon are now on sale.",
                          date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!,
                          type: .ticketAvailable),
        NotificationModel(title: "Event Cancelled",
                          body: "Sorry, Music Festival 2025 has been cancelled.",
                          date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
                          type: .eventCancelled)
    ]
}
