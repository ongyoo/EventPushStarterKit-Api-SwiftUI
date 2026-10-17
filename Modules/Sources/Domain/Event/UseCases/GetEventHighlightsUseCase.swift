//
//  GetEventHighlightsUseCase.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Foundation

/// What the home screen shows: the most popular events and everything coming up.
public struct EventHighlights: Equatable, Sendable {
    public let featured: [Event]
    public let upcoming: [Event]

    public init(featured: [Event], upcoming: [Event]) {
        self.featured = featured
        self.upcoming = upcoming
    }
}

/// Business rule: featured = the `featuredCount` most favorited events,
/// upcoming = every event, soonest first.
///
///     let highlights = try await GetEventHighlightsUseCase(repository: repository)()
public struct GetEventHighlightsUseCase: Sendable {
    public static let featuredCount = 5

    private let repository: any EventRepository

    public init(repository: any EventRepository) {
        self.repository = repository
    }

    public func callAsFunction() async throws -> EventHighlights {
        let events = try await repository.events()
        return EventHighlights(
            featured: Array(events.sorted { $0.favoriteCount > $1.favoriteCount }.prefix(Self.featuredCount)),
            upcoming: events.sorted { $0.startDate < $1.startDate }
        )
    }
}
