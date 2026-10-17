//
//  OrganizerContract.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Domain
import Foundation

// MARK: - Entity (screen model)

struct OrganizerProfile: Equatable, Sendable {
    let name: String
    let events: [Event]
}

// MARK: - Router (implemented by EventDetailCoordinator)

@MainActor
protocol OrganizerRouting: AnyObject {
    func showEvent(id: String)
}

// MARK: - Interactor

protocol OrganizerInteracting: Sendable {
    func fetchProfile() async throws -> OrganizerProfile
}
