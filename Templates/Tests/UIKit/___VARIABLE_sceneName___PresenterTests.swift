___FILEHEADER___

import Core
import Testing
import UIKit
@testable import Features

@MainActor
struct ___VARIABLE_sceneName___PresenterTests {
    private let items = [___VARIABLE_sceneName___Item(id: "1", title: "First")]

    private func makeSUT(
        _ result: Result<[___VARIABLE_sceneName___Item], any Error>
    ) -> (___VARIABLE_sceneName___Presenter, ViewSpy, RouterSpy) {
        let view = ViewSpy()
        let router = RouterSpy()
        let presenter = ___VARIABLE_sceneName___Presenter(interactor: InteractorStub(result), router: router)
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
        presenter.didSelectItem(at: 99)
        #expect(router.shownIDs == ["1"])
    }

    @Test func presenterDoesNotRetainViewOrRouter() {
        var view: ViewSpy? = ViewSpy()
        var router: RouterSpy? = RouterSpy()
        weak let weakView = view
        weak let weakRouter = router
        let presenter = ___VARIABLE_sceneName___Presenter(interactor: InteractorStub(.success(items)), router: router)
        presenter.view = view
        view = nil
        router = nil
        #expect(weakView == nil)
        #expect(weakRouter == nil)
    }

    @Test func defaultInteractorReturnsItems() async throws {
        let items = try await ___VARIABLE_sceneName___Interactor().fetchItems()
        #expect(!items.isEmpty)
    }

    @Test func storyboardScreenRendersAllStates() async throws {
        let router = RouterSpy()
        let viewController = try #require(
            ___VARIABLE_sceneName___Builder.build(router: router, interactor: InteractorStub(.success(items)))
                as? ___VARIABLE_sceneName___ViewController
        )
        viewController.loadViewIfNeeded()
        let presenter = try #require(viewController.presenter as? ___VARIABLE_sceneName___Presenter)
        await presenter.load().value

        viewController.render(.idle)
        viewController.render(.loading)
        viewController.render(.loaded([]))
        viewController.render(.failed("Oops"))
        viewController.render(.loaded(items))

        let tableView = try #require(viewController.view.subviews.compactMap { $0 as? UITableView }.first)
        #expect(tableView.numberOfRows(inSection: 0) == 1)
        _ = viewController.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        viewController.tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        #expect(router.shownIDs == ["1"])
    }
}

// MARK: - Test doubles

private struct InteractorStub: ___VARIABLE_sceneName___Interacting {
    let result: Result<[___VARIABLE_sceneName___Item], any Error>
    init(_ result: Result<[___VARIABLE_sceneName___Item], any Error>) { self.result = result }
    func fetchItems() async throws -> [___VARIABLE_sceneName___Item] { try result.get() }
}

@MainActor
private final class ViewSpy: ___VARIABLE_sceneName___ViewInput {
    private(set) var states: [Loadable<[___VARIABLE_sceneName___Item]>] = []
    func render(_ state: Loadable<[___VARIABLE_sceneName___Item]>) { states.append(state) }
}

@MainActor
private final class RouterSpy: ___VARIABLE_sceneName___Routing {
    private(set) var shownIDs: [String] = []
    func showItem(id: String) { shownIDs.append(id) }
}
