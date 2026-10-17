//
//  OrganizerInteractor.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Domain
import Foundation

/// Organizer of a given event + all events by the same organizer.
final class OrganizerInteractor: OrganizerInteracting {
    private let eventID: String
    private let organizer: GetOrganizerUseCase

    init(eventID: String, repository: any EventRepository = Container.shared.eventRepository()) {
        self.eventID = eventID
        organizer = GetOrganizerUseCase(repository: repository)
    }

    func fetchProfile() async throws -> OrganizerProfile {
        let result = try await organizer(eventID: eventID)
        return OrganizerProfile(name: result.name, events: result.events)
    }
}
