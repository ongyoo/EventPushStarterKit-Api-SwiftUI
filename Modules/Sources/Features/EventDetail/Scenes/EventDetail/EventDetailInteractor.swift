//
//  EventDetailInteractor.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Domain
import Foundation

final class EventDetailInteractor: EventDetailInteracting {
    private let eventID: String
    private let repository: any EventRepository
    private let favorites: any FavoritesRepository

    init(
        eventID: String,
        repository: any EventRepository = Container.shared.eventRepository(),
        favorites: any FavoritesRepository = Container.shared.favoritesRepository()
    ) {
        self.eventID = eventID
        self.repository = repository
        self.favorites = favorites
    }

    func fetchEvent() async throws -> Event {
        try await repository.event(id: eventID)
    }

    func isFavorite() async -> Bool {
        (try? await favorites.isFavorite(eventID: eventID)) ?? false
    }

    func toggleFavorite(_ event: Event) async throws -> Bool {
        try await favorites.toggle(event)
    }
}
