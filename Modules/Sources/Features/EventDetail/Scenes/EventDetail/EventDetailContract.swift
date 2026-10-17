//
//  EventDetailContract.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Domain
import Foundation

// MARK: - Router (implemented by EventDetailCoordinator)

@MainActor
protocol EventDetailRouting: AnyObject {
    func showOrganizer(ofEventID eventID: String)
}

// MARK: - Interactor

protocol EventDetailInteracting: Sendable {
    func fetchEvent() async throws -> Event
    func isFavorite() async -> Bool
    /// Returns the new state.
    func toggleFavorite(_ event: Event) async throws -> Bool
}
