//
//  EventEntityTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
@testable import Domain
import Foundation
import Testing

struct EventEntityTests {
    @Test func categoriesHaveTitlesIconsAndTolerateUnknownValues() throws {
        #expect(EventCategory.allCases.allSatisfy { !$0.title.isEmpty && !$0.iconName.isEmpty })
        let decoded = try JSONDecoder().decode([EventCategory].self, from: Data(#"["music","something-new"]"#.utf8))
        #expect(decoded == [.music, .all])
    }

    @Test func liveActivityAttributesFromEvent() {
        let attributes = EventActivityAttributes(event: .sample)
        #expect(attributes.eventID == Event.sample.id)
        #expect(attributes.venue == Event.sample.location.name)
        let state = EventActivityAttributes.ContentState(status: "Open", startsAt: .now)
        #expect(state.status == "Open")
        #expect(Event.sample.isFree == false)
    }
}

/// Repository double: the Domain is tested without the Data layer.
private struct InMemoryEventRepository: EventRepository {
    var all: [Event]

    func events() async throws -> [Event] { all }

    func event(id: String) async throws -> Event {
        guard let event = all.first(where: { $0.id == id }) else { throw EventRepositoryError.notFound }
        return event
    }
}

private func makeEvents(_ count: Int) -> [Event] {
    (1...count).map { index in
        Event(
            id: "\(index)",
            title: "Event \(index)",
            description: "",
            priceStartingAt: Double(index),
            organizerName: index.isMultiple(of: 3) ? "Org A" : "Org B",
            startDate: Date(timeIntervalSince1970: TimeInterval((count - index) * 86_400)),
            location: Location(name: "Venue", city: "Bangkok", latitude: 0, longitude: 0),
            thumbnailURL: nil,
            category: index.isMultiple(of: 2) ? .music : .sports,
            favoriteCount: index * 10
        )
    }
}

struct EventPagingTests {
    @Test func repositoryPagesFilteredAndSorted() async throws {
        let repository = InMemoryEventRepository(all: makeEvents(30))
        let first = try await repository.events(in: .all, page: PageRequest(page: 1, size: 8))
        #expect(first.items.count == 8 && first.hasMore)
        let dates = first.items.map(\.startDate)
        #expect(dates == dates.sorted())

        let last = try await repository.events(in: .all, page: PageRequest(page: 4, size: 8))
        #expect(last.items.count == 6 && !last.hasMore, "30 events = 8 + 8 + 8 + 6")

        let music = try await repository.events(in: .music, page: PageRequest(page: 1, size: 50))
        #expect(music.items.count == 15 && music.items.allSatisfy { $0.category == .music })
        #expect(Page.slice([1, 2, 3], PageRequest(page: 5, size: 2)).items.isEmpty)
    }
}

struct EventUseCaseTests {
    @Test func highlightsAreMostPopularAndSoonestFirst() async throws {
        let highlights = try await GetEventHighlightsUseCase(repository: InMemoryEventRepository(all: makeEvents(12)))()
        #expect(highlights.featured.map(\.id) == ["12", "11", "10", "9", "8"])
        #expect(highlights.featured.count == GetEventHighlightsUseCase.featuredCount)
        #expect(highlights.upcoming.count == 12)
        #expect(highlights.upcoming.map(\.startDate) == highlights.upcoming.map(\.startDate).sorted())
    }

    @Test func organizerHasAllTheirEventsSoonestFirst() async throws {
        let organizer = try await GetOrganizerUseCase(repository: InMemoryEventRepository(all: makeEvents(9)))(eventID: "3")
        #expect(organizer.name == "Org A")
        #expect(organizer.events.map(\.id) == ["9", "6", "3"])
        await #expect(throws: EventRepositoryError.notFound) {
            try await GetOrganizerUseCase(repository: InMemoryEventRepository(all: []))(eventID: "1")
        }
    }

    @Test func unconfiguredRepositoriesFailSafely() async {
        let container = Container()
        await #expect(throws: DomainError.notConfigured("EventRepository")) { try await container.eventRepository().events() }
        await #expect(throws: DomainError.notConfigured("FavoritesRepository")) { try await container.favoritesRepository().favorites() }
        await #expect(throws: (any Error).self) { try await container.eventRepository().event(id: "1") }
        await #expect(throws: (any Error).self) { try await container.favoritesRepository().toggle(.sample) }
        await #expect(throws: (any Error).self) { try await container.favoritesRepository().isFavorite(eventID: "1") }
        await #expect(throws: (any Error).self) { try await container.favoritesRepository().removeAll() }
        #expect(DomainError.notConfigured("X").errorDescription == "X is not configured.")
    }
}
