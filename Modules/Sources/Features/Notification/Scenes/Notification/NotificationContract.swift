//
//  NotificationContract.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Domain
import Foundation
import Navigation

// MARK: - Entity (screen model)

struct NotificationItem: Identifiable, Hashable, Sendable {
    enum Kind: Sendable {
        case reminder, newEvent, update, ticketAvailable, cancelled

        var iconName: String {
            switch self {
            case .reminder: "clock.fill"
            case .newEvent: "star.fill"
            case .update: "info.circle.fill"
            case .ticketAvailable: "ticket.fill"
            case .cancelled: "exclamationmark.triangle.fill"
            }
        }
    }

    let id: String
    let title: String
    let body: String
    let date: Date
    let kind: Kind
    /// Event to open when tapped (nil = informational only).
    let eventID: String?
}

// MARK: - View (implemented by the ViewController)

/// What the presenter can ask the view to show.
@MainActor
protocol NotificationViewInput: AnyObject {
    func render(_ state: Loadable<[NotificationItem]>)
}

// MARK: - Presenter (called by the ViewController)

@MainActor
protocol NotificationPresenting: AnyObject {
    func viewDidLoad()
    func didPullToRefresh()
    func didSelectItem(at index: Int)
}

// MARK: - Router (implemented by the feature Coordinator)

@MainActor
protocol NotificationRouting: AnyObject {
    func openEvent(id: String)
}

// MARK: - Interactor (business logic, no UI)

protocol NotificationInteracting: Sendable {
    func fetchItems() async throws -> [NotificationItem]
}
