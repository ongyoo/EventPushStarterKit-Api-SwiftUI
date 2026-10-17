//
//  EventListInteractor.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Domain
import Foundation

final class EventListInteractor: EventListInteracting {
    private let repository: any EventRepository

    init(repository: any EventRepository = Container.shared.eventRepository()) {
        self.repository = repository
    }

    func fetchEvents(category: EventCategory, page: PageRequest) async throws -> Page<Event> {
        try await repository.events(in: category, page: page)
    }
}
