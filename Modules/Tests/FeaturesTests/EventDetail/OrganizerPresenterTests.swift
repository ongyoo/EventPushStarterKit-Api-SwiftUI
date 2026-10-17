//
//  OrganizerPresenterTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Domain
@testable import Features
import Testing
import UIKit

@MainActor
struct OrganizerPresenterTests {
    @Test func interactorGroupsEventsByOrganizer() async throws {
        let twin = Event(id: "9", title: "Another", description: "", priceStartingAt: 0, organizerName: Event.sample.organizerName,
                         startDate: .now, location: Event.sample.location, thumbnailURL: nil, category: .sports, favoriteCount: 0)
        let interactor = OrganizerInteractor(eventID: "1", repository: RepositoryStub(events: Event.samples + [twin]))
        let profile = try await interactor.fetchProfile()
        #expect(profile.name == Event.sample.organizerName)
        #expect(profile.events.map(\.id) == ["9", "1"], "Soonest first (twin starts now, sample in 30 days)")
    }

    @Test func loadSuccessAndFailure() async {
        let ok = OrganizerPresenter(interactor: OrganizerInteractor(eventID: "1", repository: RepositoryStub()), router: nil)
        await ok.load()
        #expect(ok.state.value?.events.count == 1)

        let failing = OrganizerPresenter(interactor: OrganizerInteractor(eventID: "1", repository: RepositoryStub(error: StubError())), router: nil)
        await failing.load()
        #expect(failing.state == .failed("Stub failure"))

        let cancelled = OrganizerPresenter(interactor: OrganizerInteractor(eventID: "1", repository: RepositoryStub(error: CancellationError())), router: nil)
        await cancelled.load()
        #expect(cancelled.state == .idle)
    }

    @Test func selectingEventRoutes() {
        let router = RouterSpy()
        let presenter = OrganizerPresenter(interactor: OrganizerInteractor(eventID: "1", repository: RepositoryStub()), router: router)
        presenter.didSelect(.sample)
        #expect(router.eventIDs == ["1"])
    }

    @Test func builderRendersEveryState() async throws {
        for repository in [RepositoryStub(), RepositoryStub(error: StubError())] {
            let viewController = OrganizerBuilder.build(
                eventID: "1",
                router: RouterSpy(),
                interactor: OrganizerInteractor(eventID: "1", repository: repository)
            )
            render(viewController)
            try await Task.sleep(for: .milliseconds(50))
            viewController.view.layoutIfNeeded()
            #expect(viewController.title == "Organizer")
        }
    }
}

@MainActor
private final class RouterSpy: OrganizerRouting {
    private(set) var eventIDs: [String] = []
    func showEvent(id: String) { eventIDs.append(id) }
}
