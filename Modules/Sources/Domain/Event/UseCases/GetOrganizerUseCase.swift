//
//  GetOrganizerUseCase.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Core
import Foundation

/// An organizer and every event they run.
public struct Organizer: Equatable, Sendable {
    public let name: String
    public let events: [Event]

    public init(name: String, events: [Event]) {
        self.name = name
        self.events = events
    }
}

/// Business rule: the organizer of an event, with all their events, soonest first.
///
///     let organizer = try await GetOrganizerUseCase(repository: repository)(eventID: "42")
public struct GetOrganizerUseCase: Sendable {
    private let repository: any EventRepository

    public init(repository: any EventRepository) {
        self.repository = repository
    }

    public func callAsFunction(eventID: String) async throws -> Organizer {
        let event = try await repository.event(id: eventID)
        let events = try await repository.events()
            .filter { $0.organizerName == event.organizerName }
            .sorted { $0.startDate < $1.startDate }
        return Organizer(name: event.organizerName, events: events)
    }
}
