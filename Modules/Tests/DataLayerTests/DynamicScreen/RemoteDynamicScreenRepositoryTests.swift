//
//  RemoteDynamicScreenRepositoryTests.swift
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

struct RemoteDynamicScreenRepositoryTests {
    private let fresh = Data(#"{"schemaVersion":1,"id":"promo","body":[]}"#.utf8)

    private func repository(_ responses: [String: Result<Data, NetworkError>], cache: InMemoryStore = InMemoryStore()) -> (RemoteDynamicScreenRepository, MockAPIClient) {
        let api = MockAPIClient(responses: responses)
        return (RemoteDynamicScreenRepository(api: api, cache: cache, schemaVersion: 1, language: { "th" }), api)
    }

    @Test func freshFromTheBFFAndCached() async throws {
        let cache = InMemoryStore()
        let (repo, api) = repository(["bff/screens/promo": .success(fresh)], cache: cache)
        let payload = try await repo.screen(id: "promo")
        #expect(payload.source == .network)
        #expect(payload.json == fresh)
        #expect(api.requestedPaths == ["bff/screens/promo"])
        #expect(cache[StorageKey<Data>("bff.screen.promo")] == fresh)
    }

    @Test func offlineFallsBackToTheLastGoodCopy() async throws {
        let cache = InMemoryStore()
        cache[StorageKey<Data>("bff.screen.promo")] = fresh
        let (repo, _) = repository(["bff/screens/promo": .failure(.noConnection)], cache: cache)
        let payload = try await repo.screen(id: "promo")
        #expect(payload.source == .cache)
        #expect(payload.json == fresh)
    }

    @Test func thenToTheCopyShippedInTheApp() async throws {
        let (repo, _) = repository([:])
        let payload = try await repo.screen(id: "showcase")
        #expect(payload.source == .bundled)
        #expect(!payload.json.isEmpty)
    }

    @Test func unknownScreenOfflineIsUnavailable() async {
        let (repo, _) = repository([:])
        await #expect(throws: DynamicScreenRepositoryError.unavailable(id: "nope")) {
            try await repo.screen(id: "nope")
        }
        #expect(DynamicScreenRepositoryError.unavailable(id: "nope").errorDescription != nil)
    }

    @Test func fixturesServeTheMockAPIAndTheEndpointAsksForSchemaAndLanguage() throws {
        #expect(DynamicScreenFixtures.responses.keys.sorted() == ["bff/screens/showcase", "bff/screens/songkran"])
        let request = try DynamicScreenEndpoint.screen(id: "promo", schemaVersion: 1, language: "th").makeRequest()
        #expect(request.url?.query?.contains("schema=1") == true)
        #expect(request.url?.query?.contains("lang=th") == true)
    }

    @Test func dataAssemblyRegistersTheRepository() async throws {
        let container = Container()
        container.apiClient.register { MockAPIClient(responses: [:]) }
        container.preferences.register { InMemoryStore() }
        DataAssembly.register(in: container, dynamicScreenSchemaVersion: 1)
        let payload = try await container.dynamicScreenRepository().screen(id: "songkran")
        #expect(payload.source == .bundled)
    }
}
