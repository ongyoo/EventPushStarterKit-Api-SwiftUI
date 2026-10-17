//
//  EventListContract.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Domain
import Foundation

// MARK: - Router (implemented by EventListCoordinator)

@MainActor
protocol EventListRouting: AnyObject {
    func showEvent(id: String)
}

// MARK: - Interactor

protocol EventListInteracting: Sendable {
    /// One page of events of `category`.
    func fetchEvents(category: EventCategory, page: PageRequest) async throws -> Page<Event>
}
