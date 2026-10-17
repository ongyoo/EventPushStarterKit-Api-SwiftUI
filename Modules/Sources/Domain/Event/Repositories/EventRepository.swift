//
//  EventRepository.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Foundation

/// What features use to get events. Features depend on this protocol only;
/// the implementation lives in the Data layer (`RemoteEventRepository`).
public protocol EventRepository: Sendable {
    func events() async throws -> [Event]
    func event(id: String) async throws -> Event
    /// One page of `category` (all for `.all`), soonest first.
    func events(in category: EventCategory, page: PageRequest) async throws -> Page<Event>
}

public extension EventRepository {
    /// Default: page the full list in memory. Override when the API supports
    /// paging (`?page=` / `?offset=&limit=`) so only one page is downloaded.
    func events(in category: EventCategory, page: PageRequest) async throws -> Page<Event> {
        let all = try await events()
            .filter { category == .all || $0.category == category }
            .sorted { $0.startDate < $1.startDate }
        return .slice(all, page)
    }
}

/// Domain errors with user-facing messages.
public enum EventRepositoryError: Error, LocalizedError, Equatable {
    case notFound

    public var errorDescription: String? {
        switch self {
        case .notFound: "This event is no longer available."
        }
    }
}

public extension Container {
    /// Registered by the composition root (`AppAssembly`) with the Data implementation.
    var eventRepository: Dependency<any EventRepository> {
        Dependency(self) { UnconfiguredEventRepository() }.singleton
    }
}

/// Default until the app registers the real repository: fails safely, never crashes.
struct UnconfiguredEventRepository: EventRepository {
    func events() async throws -> [Event] { throw DomainError.notConfigured("EventRepository") }
    func event(id: String) async throws -> Event { throw DomainError.notConfigured("EventRepository") }
}
