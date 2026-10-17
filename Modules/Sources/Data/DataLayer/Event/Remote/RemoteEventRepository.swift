//
//  RemoteEventRepository.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import DataSources
import Domain
import Foundation

/// Calls the API and keeps the last list in memory, so opening a detail
/// screen right after the list doesn't hit the network again.
public final class RemoteEventRepository: EventRepository {
    private let api: any APIClient
    private let cache = EventCache()

    /// Production: registered by `DataAssembly`; tests: `RemoteEventRepository(api: MockAPIClient(...))`.
    public init(api: any APIClient) {
        self.api = api
    }

    /// All events (also refreshes the in-memory cache).
    public func events() async throws -> [Event] {
        let dtos: [EventDTO] = try await api.send(EventEndpoint.list)
        let events = dtos.map { $0.toDomain() }
        await cache.store(events)
        return events
    }

    /// One event, from cache when possible. Throws `.notFound`.
    public func event(id: String) async throws -> Event {
        if let cached = await cache.event(id: id) { return cached }
        guard let event = try await events().first(where: { $0.id == id }) else {
            throw EventRepositoryError.notFound
        }
        return event
    }
}

/// Actor = thread-safe without locks.
private actor EventCache {
    private var byID: [String: Event] = [:]

    func store(_ events: [Event]) {
        byID = Dictionary(events.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
    }

    func event(id: String) -> Event? {
        byID[id]
    }
}
