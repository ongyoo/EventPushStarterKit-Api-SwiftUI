___FILEHEADER___

import Core
import Foundation

/// Turns user actions into interactor calls and results into view updates.
@MainActor
final class ___VARIABLE_sceneName___Presenter: ___VARIABLE_sceneName___Presenting {
    weak var view: (any ___VARIABLE_sceneName___ViewInput)?
    private weak var router: (any ___VARIABLE_sceneName___Routing)?
    private let interactor: any ___VARIABLE_sceneName___Interacting
    /// Cancels in-flight work when the presenter (= the screen) is released.
    private let tasks = TaskBag()
    private(set) var items: [___VARIABLE_sceneName___Item] = []

    init(interactor: any ___VARIABLE_sceneName___Interacting, router: (any ___VARIABLE_sceneName___Routing)?) {
        self.interactor = interactor
        self.router = router
    }

    func viewDidLoad() {
        load()
    }

    func didPullToRefresh() {
        load()
    }

    func didSelectItem(at index: Int) {
        guard let item = items[safe: index] else { return }
        router?.showItem(id: item.id)
    }

    /// Exposed for tests: `await presenter.load().value`.
    @discardableResult
    func load() -> Task<Void, Never> {
        tasks.cancelAll()
        view?.render(.loading)
        // [weak self]: the task must not keep a closed screen alive.
        return Task { [weak self, interactor] in
            do {
                let items = try await interactor.fetchItems()
                self?.items = items
                self?.view?.render(.loaded(items))
            } catch is CancellationError {
                return
            } catch {
                self?.view?.render(.failed(error.localizedDescription))
            }
        }
        .store(in: tasks)
    }
}
