//
//  RemoteEventRepositoryTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Core
@testable import DataLayer
import DataSources
import Domain
import Testing

struct EventRepositoryTests {
    private func makeRepository() -> RemoteEventRepository {
        RemoteEventRepository(api: MockAPIClient(responses: EventFixtures.responses.mapValues { .success($0) }))
    }

    @Test func decodesAndMapsFixture() async throws {
        let events = try await makeRepository().events()
        #expect(events.count == 30)
        #expect(events.first?.title == "King's Cup 51st Football Championship")
        #expect(events.first?.thumbnailURL != nil)
    }

    @Test func findsEventByID() async throws {
        let event = try await makeRepository().event(id: "3")
        #expect(event.category == .music)
    }

    @Test func throwsNotFoundForUnknownID() async {
        await #expect(throws: EventRepositoryError.notFound) {
            try await makeRepository().event(id: "missing")
        }
    }
}
