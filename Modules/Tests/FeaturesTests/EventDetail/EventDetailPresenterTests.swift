//
//  EventDetailPresenterTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Domain
@testable import Features
import Testing
import UIKit

@MainActor
struct EventDetailPresenterTests {
    @Test func favoriteChangesAreTrackedOnlyWhenSaved() async {
        let analytics = RecordingAnalytics()
        let presenter = EventDetailPresenter(
            interactor: EventDetailInteractor(eventID: "1", repository: RepositoryStub(), favorites: FavoritesStub()),
            router: nil,
            analytics: analytics
        )
        await presenter.load()
        await presenter.didTapFavorite()
        #expect(analytics.events == [AnalyticsEvent("favorite_toggled", ["event_id": "1", "is_favorite": true])])

        let failing = EventDetailPresenter(
            interactor: EventDetailInteractor(eventID: "1", repository: RepositoryStub(), favorites: FavoritesStub(failing: true)),
            router: nil,
            analytics: analytics
        )
        await failing.load()
        await failing.didTapFavorite()
        #expect(analytics.events.count == 1, "Failed saves are not tracked")
    }

    @Test func loadSuccess() async {
        let presenter = EventDetailPresenter(interactor: EventDetailInteractor(eventID: "1", repository: RepositoryStub(), favorites: FavoritesStub()), router: nil)
        await presenter.load()
        #expect(presenter.state == .loaded(.sample))
    }

    @Test func loadNotFoundShowsMessage() async {
        let presenter = EventDetailPresenter(interactor: EventDetailInteractor(eventID: "x", repository: RepositoryStub(), favorites: FavoritesStub()), router: nil)
        await presenter.load()
        #expect(presenter.state == .failed(EventRepositoryError.notFound.localizedDescription))
    }

    @Test func cancelledLoadReturnsToIdle() async {
        let repository = RepositoryStub(error: CancellationError())
        let presenter = EventDetailPresenter(interactor: EventDetailInteractor(eventID: "1", repository: repository, favorites: FavoritesStub()), router: nil)
        await presenter.load()
        #expect(presenter.state == .idle)
    }

    @Test func organizerTapRoutesOnlyWhenLoaded() async {
        let router = RouterSpy()
        let presenter = EventDetailPresenter(interactor: EventDetailInteractor(eventID: "1", repository: RepositoryStub(), favorites: FavoritesStub()), router: router)
        presenter.didTapOrganizer()
        #expect(router.organizerIDs.isEmpty)

        await presenter.load()
        presenter.didTapOrganizer()
        #expect(router.organizerIDs == ["1"])
    }

    @Test func favoriteToggleIsOptimisticAndRollsBackOnError() async {
        let presenter = EventDetailPresenter(interactor: EventDetailInteractor(eventID: "1", repository: RepositoryStub(), favorites: FavoritesStub()), router: nil)
        await presenter.didTapFavorite()
        #expect(!presenter.isFavorite, "Nothing loaded yet: ignored")

        await presenter.load()
        await presenter.didTapFavorite()
        #expect(presenter.isFavorite)
        await presenter.didTapFavorite()
        #expect(!presenter.isFavorite)

        let failing = EventDetailPresenter(interactor: EventDetailInteractor(eventID: "1", repository: RepositoryStub(), favorites: FavoritesStub(failing: true)), router: nil)
        await failing.load()
        await failing.didTapFavorite()
        #expect(!failing.isFavorite, "Rolled back")
    }

    @Test func presenterDoesNotRetainRouter() {
        var router: RouterSpy? = RouterSpy()
        weak let weakRouter = router
        let presenter = EventDetailPresenter(interactor: EventDetailInteractor(eventID: "1", repository: RepositoryStub(), favorites: FavoritesStub()), router: router)
        router = nil
        #expect(weakRouter == nil)
        _ = presenter
    }

    @Test func builderRendersLoadingLoadedAndFailed() async throws {
        for repository in [RepositoryStub(), RepositoryStub(error: StubError())] {
            let viewController = EventDetailBuilder.build(
                eventID: "1",
                router: RouterSpy(),
                interactor: EventDetailInteractor(eventID: "1", repository: repository, favorites: FavoritesStub())
            )
            render(viewController)
            try await Task.sleep(for: .milliseconds(50))
            viewController.view.layoutIfNeeded()
            #expect(viewController.title == "Event")
        }
    }
}

@MainActor
private final class RouterSpy: EventDetailRouting {
    private(set) var organizerIDs: [String] = []
    func showOrganizer(ofEventID eventID: String) { organizerIDs.append(eventID) }
}
