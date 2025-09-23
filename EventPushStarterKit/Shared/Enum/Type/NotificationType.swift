//
//  NotificationType.swift
//  EventPush
//
//  Created by Nathat Kuanthanom on 9/4/25.
//

import Foundation

enum NotificationType {
    case eventReminder
    case newEvent
    case eventUpdate
    case ticketAvailable
    case eventCancelled

    var iconName: String {
        switch self {
        case .eventReminder: return "clock.fill"
        case .newEvent: return "star.fill"
        case .eventUpdate: return "info.circle.fill"
        case .ticketAvailable: return "ticket.fill"
        case .eventCancelled: return "exclamationmark.triangle.fill"
        }
    }
}
