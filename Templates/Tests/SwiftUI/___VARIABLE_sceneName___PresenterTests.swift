___FILEHEADER___

import Core
import Testing
import UIKit
@testable import Features

@MainActor
struct ___VARIABLE_sceneName___PresenterTests {
    private let items = [___VARIABLE_sceneName___Item(id: "1", title: "First")]

    @Test func loadSuccessShowsItems() async {
        let presenter = ___VARIABLE_sceneName___Presenter(interactor: InteractorStub(.success(items)), router: nil)
        await presenter.load()
        #expect(presenter.state == .loaded(items))
    }

    @Test func loadFailureShowsMessage() async {
        let presenter = ___VARIABLE_sceneName___Presenter(interactor: InteractorStub(.failure(StubError())), router: nil)
        await presenter.load()
        #expect(presenter.state == .failed(StubError().localizedDescription))
    }

    @Test func reappearingDoesNotReload() async {
        let presenter = ___VARIABLE_sceneName___Presenter(interactor: InteractorStub(.success(items)), router: nil)
        await presenter.loadIfNeeded()
        await presenter.loadIfNeeded()       // e.g. back from a pushed screen
        #expect(presenter.state == .loaded(items))
    }

    @Test func cancelledLoadReturnsToIdle() async {
        let presenter = ___VARIABLE_sceneName___Presenter(interactor: InteractorStub(.failure(CancellationError())), router: nil)
        await presenter.load()
        #expect(presenter.state == .idle)
    }

    @Test func selectingItemRoutes() {
        let router = RouterSpy()
        let presenter = ___VARIABLE_sceneName___Presenter(interactor: InteractorStub(.success(items)), router: router)
        presenter.didSelect(items[0])
        #expect(router.shownIDs == ["1"])
    }

    @Test func presenterDoesNotRetainRouter() {
        var router: RouterSpy? = RouterSpy()
        weak let weakRouter = router
        let presenter = ___VARIABLE_sceneName___Presenter(interactor: InteractorStub(.success(items)), router: router)
        router = nil
        #expect(weakRouter == nil)
        _ = presenter
    }

    @Test func defaultInteractorReturnsItems() async throws {
        let items = try await ___VARIABLE_sceneName___Interactor().fetchItems()
        #expect(!items.isEmpty)
    }

    @Test func builderRendersScreen() {
        let router = RouterSpy()
        let viewController = ___VARIABLE_sceneName___Builder.build(router: router, interactor: InteractorStub(.success(items)))
        viewController.loadViewIfNeeded()
        viewController.view.layoutIfNeeded()
        #expect(viewController.title == "___VARIABLE_sceneName___")
    }
}

// MARK: - Test doubles

private struct InteractorStub: ___VARIABLE_sceneName___Interacting {
    let result: Result<[___VARIABLE_sceneName___Item], any Error>
    init(_ result: Result<[___VARIABLE_sceneName___Item], any Error>) { self.result = result }
    func fetchItems() async throws -> [___VARIABLE_sceneName___Item] { try result.get() }
}

@MainActor
private final class RouterSpy: ___VARIABLE_sceneName___Routing {
    private(set) var shownIDs: [String] = []
    func showItem(id: String) { shownIDs.append(id) }
}
