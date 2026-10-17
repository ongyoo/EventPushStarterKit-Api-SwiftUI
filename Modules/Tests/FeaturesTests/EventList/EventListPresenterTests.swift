//
//  EventListPresenterTests.swift
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
struct EventListPresenterTests {
    /// 20 events across categories, served by the default in-memory paging.
    private static let many: [Event] = (1...20).map { index in
        Event(id: "\(index)", title: "Event \(index)", description: "", priceStartingAt: 0, organizerName: "",
              startDate: .now.addingTimeInterval(Double(index) * 3600), location: Event.sample.location,
              thumbnailURL: nil, category: index.isMultiple(of: 2) ? .music : .sports, favoriteCount: 0)
    }

    private func makePresenter(
        category: EventCategory = .all,
        repository: RepositoryStub = RepositoryStub(events: many),
        router: RouterSpy? = nil
    ) -> EventListPresenter {
        EventListPresenter(category: category, interactor: EventListInteractor(repository: repository), router: router)
    }

    @Test func firstPageThenLoadMoreToTheEnd() async {
        let presenter = makePresenter()
        await presenter.loadIfNeeded()
        #expect(presenter.paginator.items.count == EventListPresenter.pageSize)
        #expect(presenter.title == L10n.Events.allTitle)

        await presenter.didShow(presenter.paginator.items.last!)   // near the end: next page
        await presenter.didTapRetryMore()                          // = load next page
        #expect(presenter.paginator.items.count == 20)
        #expect(!presenter.paginator.hasMore)

        await presenter.loadIfNeeded()                             // already loaded: no reset
        #expect(presenter.paginator.items.count == 20)
    }

    @Test func categoryChangeRestartsPaging() async {
        let presenter = makePresenter()
        await presenter.load()
        await presenter.didSelectCategory(.all)                   // same: ignored
        await presenter.didSelectCategory(.music)
        #expect(presenter.paginator.items.allSatisfy { $0.category == .music })
        #expect(presenter.title == L10n.category(.music))
    }

    @Test func failureShowsError() async {
        let presenter = makePresenter(repository: RepositoryStub(error: StubError()))
        await presenter.load()
        #expect(presenter.paginator.phase == .failed("Stub failure"))
    }

    @Test func selectingEventRoutes() {
        let router = RouterSpy()
        let presenter = makePresenter(router: router)
        presenter.didSelect(.sample)
        #expect(router.eventIDs == ["1"])
    }

    @Test func builderRendersEveryState() async throws {
        for (category, repository) in [(EventCategory.all, RepositoryStub(events: Self.many)), (.education, RepositoryStub()), (.all, RepositoryStub(error: StubError()))] {
            let viewController = EventListBuilder.build(
                category: category,
                router: RouterSpy(),
                interactor: EventListInteractor(repository: repository)
            )
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
            window.rootViewController = UINavigationController(rootViewController: viewController)
            window.makeKeyAndVisible()
            try await Task.sleep(for: .milliseconds(50))
            viewController.view.layoutIfNeeded()
            #expect(viewController.title != nil)
        }
    }
}

@MainActor
private final class RouterSpy: EventListRouting {
    private(set) var eventIDs: [String] = []
    func showEvent(id: String) { eventIDs.append(id) }
}
