//
//  HomePresenterTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Domain
@testable import Features
import Navigation
import Testing
import UIKit

@MainActor
struct HomePresenterTests {
    private let content = HomeContent(featured: Event.samples, upcoming: Event.samples)

    @Test func loadSuccessShowsContent() async {
        let presenter = HomePresenter(interactor: InteractorStub(.success(content)), router: nil)
        await presenter.load()
        #expect(presenter.state == .loaded(content))
        #expect(presenter.visibleUpcoming == Event.samples)
    }

    @Test func loadFailureShowsMessage() async {
        let presenter = HomePresenter(interactor: InteractorStub(.failure(StubError())), router: nil)
        await presenter.load()
        #expect(presenter.state == .failed("Stub failure"))
        #expect(presenter.visibleUpcoming.isEmpty)
    }

    @Test func cancelledFirstLoadReturnsToIdle() async {
        let presenter = HomePresenter(interactor: InteractorStub(.failure(CancellationError())), router: nil)
        await presenter.load()
        #expect(presenter.state == .idle)
    }

    @Test func refreshKeepsContentVisible() async {
        let interactor = InteractorStub(.success(content))
        let presenter = HomePresenter(interactor: interactor, router: nil)
        await presenter.load()
        await presenter.load()
        #expect(presenter.state == .loaded(content))
    }

    @Test func reappearingKeepsContentAndFiltersUntilStale() async {
        let interactor = CountingInteractor(content)
        let presenter = HomePresenter(interactor: interactor, router: nil)
        await presenter.loadIfNeeded()
        #expect(interactor.calls == 1 && presenter.animatesEntrance)

        presenter.searchText = "cup"
        await presenter.loadIfNeeded()                 // back from detail / tab switch
        #expect(interactor.calls == 1, "No reload")
        #expect(presenter.searchText == "cup", "Filters kept")
        #expect(!presenter.animatesEntrance, "Entrance animations only once")

        await presenter.loadIfNeeded(now: .now.addingTimeInterval(HomePresenter.staleAfter + 1))
        #expect(interactor.calls == 2, "Stale content refreshed in the background")
        #expect(presenter.searchText == "cup")

        await presenter.load()                         // pull to refresh always reloads
        #expect(interactor.calls == 3)
    }

    @Test func rowsGroupByColumns() {
        let events = (1...5).map { index in
            Event(id: "\(index)", title: "", description: "", priceStartingAt: 0, organizerName: "", startDate: .now,
                  location: Event.sample.location, thumbnailURL: nil, category: .music, favoriteCount: 0)
        }
        #expect(EventRowGroup.make(events, columns: 1).count == 5)
        let pairs = EventRowGroup.make(events, columns: 2)
        #expect(pairs.map(\.events.count) == [2, 2, 1])
        #expect(pairs.first?.id == "row.1")
        #expect(EventRowGroup.make([], columns: 3).isEmpty)
        #expect(EventRowGroup.make(events, columns: 0).count == 5)
    }

    @Test func filtersByCategoryAndSearch() async {
        let presenter = HomePresenter(interactor: InteractorStub(.success(content)), router: nil)
        await presenter.load()

        presenter.didSelectCategory(.music)
        #expect(presenter.visibleUpcoming.map(\.id) == ["2"])

        presenter.didSelectCategory(.all)
        presenter.searchText = "tokyo"
        #expect(presenter.visibleUpcoming.map(\.id) == ["3"])

        presenter.searchText = "   "
        #expect(presenter.visibleUpcoming.count == Event.samples.count)
    }

    @Test func homeShowsAtMostTheLimitAndCountsTheRest() async {
        let many = (1...(HomePresenter.upcomingLimit + 5)).map { index in
            Event(id: "\(index)", title: "Event \(index)", description: "", priceStartingAt: 0, organizerName: "",
                  startDate: .now, location: Event.sample.location, thumbnailURL: nil, category: .music, favoriteCount: 0)
        }
        let presenter = HomePresenter(interactor: InteractorStub(.success(HomeContent(featured: [], upcoming: many))), router: nil)
        await presenter.load()
        #expect(presenter.visibleUpcoming.count == HomePresenter.upcomingLimit)
        #expect(presenter.matchingUpcomingCount == many.count)
        presenter.searchText = "Event 2"  // 2, 20...25
        #expect(presenter.matchingUpcomingCount == 7)
        #expect(presenter.visibleUpcoming.count == 7)
    }

    @Test func userActionsAreTracked() async {
        let analytics = RecordingAnalytics()
        let presenter = HomePresenter(interactor: InteractorStub(.success(content)), router: nil, analytics: analytics)
        await presenter.load()
        presenter.didSelectFeatured(.sample)
        presenter.didSelectEvent(.sample)
        presenter.didSelectCategory(.music)
        presenter.didSelectCategory(.music)          // same category: not tracked twice
        presenter.didTapSeeAll()
        #expect(analytics.eventNames == ["event_selected", "event_selected", "category_selected", "see_all_tapped"])
        #expect(analytics.events[0].parameters["source"] == "popular")
        #expect(analytics.events[1].parameters["source"] == "upcoming")
        #expect(analytics.events[3].parameters["category"] == "music")
    }

    @Test func userActionsRoute() {
        let router = RouterSpy()
        let presenter = HomePresenter(interactor: InteractorStub(.success(content)), router: router)
        presenter.didSelectCategory(.sports)
        presenter.didSelectFeatured(.sample)
        presenter.didSelectEvent(.sample)
        presenter.didTapSeeAll()
        presenter.didTapNotifications()
        #expect(router.calls == ["featured:1", "detail:1", "all:sports", "notifications"])
    }

    @Test func presenterDoesNotRetainRouter() {
        var router: RouterSpy? = RouterSpy()
        weak let weakRouter = router
        let presenter = HomePresenter(interactor: InteractorStub(.success(content)), router: router)
        router = nil
        #expect(weakRouter == nil)
        _ = presenter
    }

    @Test func builderRendersEveryState() async {
        for result in [Result<HomeContent, any Error>.success(content), .failure(StubError())] {
            let viewController = HomeBuilder.build(router: RouterSpy(), interactor: InteractorStub(result))
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
            window.rootViewController = viewController
            window.makeKeyAndVisible()
            viewController.view.layoutIfNeeded()
            #expect((viewController as? NavigationBarHiding)?.prefersNavigationBarHidden == true)
        }
    }
}

@MainActor
struct HomeInteractorTests {
    @Test func buildsFeaturedAndUpcoming() async throws {
        let older = Event.samples[2]
        let interactor = HomeInteractor(repository: RepositoryStub(events: Event.samples))
        let content = try await interactor.loadContent()

        #expect(content.featured.first?.id == "1")
        #expect(content.featured.count == min(Event.samples.count, GetEventHighlightsUseCase.featuredCount))
        #expect(content.upcoming.map(\.startDate) == content.upcoming.map(\.startDate).sorted())
        #expect(content.upcoming.contains(older))
    }

    @Test func limitsFeaturedCount() async throws {
        let many = (0..<10).map { index in
            Event(id: "\(index)", title: "E\(index)", description: "", priceStartingAt: 0, organizerName: "",
                  startDate: .now, location: Event.sample.location, thumbnailURL: nil, category: .music, favoriteCount: index)
        }
        let content = try await HomeInteractor(repository: RepositoryStub(events: many)).loadContent()
        #expect(content.featured.count == GetEventHighlightsUseCase.featuredCount)
        #expect(content.featured.first?.id == "9")
    }
}

// MARK: - Test doubles

private final class CountingInteractor: HomeInteracting, @unchecked Sendable {
    private let content: HomeContent
    private(set) var calls = 0
    init(_ content: HomeContent) { self.content = content }
    func loadContent() async throws -> HomeContent {
        calls += 1
        return content
    }
}

private struct InteractorStub: HomeInteracting {
    let result: Result<HomeContent, any Error>
    init(_ result: Result<HomeContent, any Error>) { self.result = result }
    func loadContent() async throws -> HomeContent { try result.get() }
}

@MainActor
private final class RouterSpy: HomeRouting {
    private(set) var calls: [String] = []
    func showFeaturedEvent(id: String) { calls.append("featured:\(id)") }
    func showEventDetail(id: String) { calls.append("detail:\(id)") }
    func showAllEvents(category: EventCategory) { calls.append("all:\(category.rawValue)") }
    func showNotifications() { calls.append("notifications") }
}
