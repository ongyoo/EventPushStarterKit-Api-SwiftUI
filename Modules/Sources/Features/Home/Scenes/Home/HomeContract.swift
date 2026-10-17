//
//  HomeContract.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Domain
import Foundation

// MARK: - Entity (screen model)

/// Everything the Home screen shows, prepared by the Interactor.
struct HomeContent: Equatable, Sendable {
    /// Most popular events (carousel).
    let featured: [Event]
    /// Upcoming events sorted by date (list).
    let upcoming: [Event]
}

// MARK: - Router (implemented by HomeCoordinator)

@MainActor
protocol HomeRouting: AnyObject {
    /// From the "Popular" carousel (hero transition from the card).
    func showFeaturedEvent(id: String)
    /// From the "Upcoming" list.
    func showEventDetail(id: String)
    func showAllEvents(category: EventCategory)
    func showNotifications()
}

// MARK: - Interactor

protocol HomeInteracting: Sendable {
    func loadContent() async throws -> HomeContent
}
