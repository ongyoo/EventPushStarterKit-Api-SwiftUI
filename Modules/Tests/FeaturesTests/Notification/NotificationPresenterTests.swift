//
//  NotificationPresenterTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
@testable import Features
import Testing
import UIKit

@MainActor
struct NotificationPresenterTests {
    private let items = [
        NotificationItem(id: "n1", title: "First", body: "Body", date: .now, kind: .reminder, eventID: "1"),
        NotificationItem(id: "n2", title: "Info", body: "Body", date: .now, kind: .cancelled, eventID: nil),
    ]

    private func makeSUT(
        _ result: Result<[NotificationItem], any Error>
    ) -> (NotificationPresenter, ViewSpy, RouterSpy) {
        let view = ViewSpy()
        let router = RouterSpy()
        let presenter = NotificationPresenter(interactor: InteractorStub(result), router: router)
        presenter.view = view
        return (presenter, view, router)
    }

    @Test func loadSuccessRendersLoadingThenItems() async {
        let (presenter, view, _) = makeSUT(.success(items))
        await presenter.load().value
        #expect(view.states == [.loading, .loaded(items)])
    }

    @Test func loadFailureRendersError() async {
        let (presenter, view, _) = makeSUT(.failure(StubError()))
        await presenter.load().value
        #expect(view.states.last == .failed("Stub failure"))
    }

    @Test func cancelledLoadRendersNothingMore() async {
        let (presenter, view, _) = makeSUT(.failure(CancellationError()))
        await presenter.load().value
        #expect(view.states == [.loading])
    }

    @Test func lifecycleActionsTriggerLoad() async {
        let (presenter, view, _) = makeSUT(.success(items))
        presenter.viewDidLoad()
        presenter.didPullToRefresh()
        await presenter.load().value
        #expect(view.states.contains(.loaded(items)))
    }

    @Test func selectingItemRoutesAndIgnoresBadIndex() async {
        let (presenter, _, router) = makeSUT(.success(items))
        await presenter.load().value
        presenter.didSelectItem(at: 0)
        presenter.didSelectItem(at: 1)
        presenter.didSelectItem(at: 99)
        #expect(router.shownIDs == ["1"])
    }

    @Test func presenterDoesNotRetainViewOrRouter() {
        var view: ViewSpy? = ViewSpy()
        var router: RouterSpy? = RouterSpy()
        weak let weakView = view
        weak let weakRouter = router
        let presenter = NotificationPresenter(interactor: InteractorStub(.success(items)), router: router)
        presenter.view = view
        view = nil
        router = nil
        #expect(weakView == nil)
        #expect(weakRouter == nil)
    }

    @Test func defaultInteractorReturnsNewestFirst() async throws {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let items = try await NotificationInteractor(now: { now }).fetchItems()
        #expect(items.count == 5)
        #expect(items.first?.date == now)
        #expect(items.map(\.date) == items.map(\.date).sorted(by: >))
        #expect(Set(items.map(\.kind.iconName)).count == 5)
    }

    @Test func storyboardScreenRendersAllStates() async throws {
        let router = RouterSpy()
        let viewController = try #require(
            NotificationBuilder.build(router: router, interactor: InteractorStub(.success(items)))
                as? NotificationViewController
        )
        viewController.loadViewIfNeeded()
        let presenter = try #require(viewController.presenter as? NotificationPresenter)
        await presenter.load().value

        viewController.render(.idle)
        viewController.render(.loading)
        viewController.render(.loaded([]))
        viewController.render(.failed("Oops"))
        viewController.render(.loaded(items))

        let tableView = try #require(viewController.view.subviews.compactMap { $0 as? UITableView }.first)
        #expect(tableView.numberOfRows(inSection: 0) == 2)
        _ = viewController.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        _ = viewController.tableView(tableView, cellForRowAt: IndexPath(row: 1, section: 0))
        viewController.tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        #expect(router.shownIDs == ["1"])
    }
}

// MARK: - Test doubles

private struct InteractorStub: NotificationInteracting {
    let result: Result<[NotificationItem], any Error>
    init(_ result: Result<[NotificationItem], any Error>) { self.result = result }
    func fetchItems() async throws -> [NotificationItem] { try result.get() }
}

@MainActor
private final class ViewSpy: NotificationViewInput {
    private(set) var states: [Loadable<[NotificationItem]>] = []
    func render(_ state: Loadable<[NotificationItem]>) { states.append(state) }
}

@MainActor
private final class RouterSpy: NotificationRouting {
    private(set) var shownIDs: [String] = []
    func openEvent(id: String) { shownIDs.append(id) }
}
