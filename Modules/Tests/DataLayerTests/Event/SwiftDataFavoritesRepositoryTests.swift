//
//  SwiftDataFavoritesRepositoryTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Core
@testable import DataLayer
import DataSources
import Domain
import Foundation
import Testing

struct FavoritesRepositoryTests {
    private func makeRepository() -> SwiftDataFavoritesRepository {
        SwiftDataFavoritesRepository(modelContainer: Database(models: DataSchema.models, inMemory: true).container)
    }

    @Test func toggleAddsAndRemoves() async throws {
        let repository = makeRepository()
        #expect(try await repository.isFavorite(eventID: "1") == false)
        #expect(try await repository.toggle(.sample) == true)
        #expect(try await repository.isFavorite(eventID: "1"))
        #expect(try await repository.favorites().map(\.id) == ["1"])
        #expect(try await repository.toggle(.sample) == false)
        #expect(try await repository.favorites().isEmpty)
    }

    @Test func newestFirstAndRemoveAll() async throws {
        let repository = makeRepository()
        for event in Event.samples { _ = try await repository.toggle(event) }
        let ids = try await repository.favorites().map(\.id)
        #expect(Set(ids) == Set(Event.samples.map(\.id)))
        try await repository.removeAll()
        #expect(try await repository.favorites().isEmpty)
    }

    @Test func databaseIsPersistentWithFallback() {
        let persistent = Database(models: DataSchema.models, fileName: "Tests-\(UUID().uuidString).store")
        #expect(persistent.isPersistent)
        #expect(!Database(models: DataSchema.models, inMemory: true).isPersistent)
    }

    @Test func dataAssemblyPlugsImplementationsIntoDomainContracts() async throws {
        let container = Container()
        container.database.register { Database(models: DataSchema.models, inMemory: true) }
        container.apiClient.register { MockAPIClient(responses: EventFixtures.responses.mapValues { .success($0) }) }
        DataAssembly.register(in: container)

        #expect(container.favoritesRepository() is SwiftDataFavoritesRepository)
        #expect(container.eventRepository() is RemoteEventRepository)
        #expect(try await container.favoritesRepository().toggle(.sample))
        #expect(try await container.eventRepository().events().count == 30)
    }
}
