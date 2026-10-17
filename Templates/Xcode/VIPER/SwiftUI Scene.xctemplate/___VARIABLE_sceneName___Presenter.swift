___FILEHEADER___

import Core
import Foundation
import Observation

/// Turns user actions into interactor calls and results into view state.
/// `@Observable`: the SwiftUI view re-renders only for properties it reads.
@MainActor
@Observable
final class ___VARIABLE_sceneName___Presenter {
    private(set) var state: Loadable<[___VARIABLE_sceneName___Item]> = .idle

    @ObservationIgnored private let interactor: any ___VARIABLE_sceneName___Interacting
    @ObservationIgnored private weak var router: (any ___VARIABLE_sceneName___Routing)?

    init(interactor: any ___VARIABLE_sceneName___Interacting, router: (any ___VARIABLE_sceneName___Routing)?) {
        self.interactor = interactor
        self.router = router
    }

    /// First appearance only (`.task {}` runs on every appearance): coming back
    /// keeps the content and the scroll position.
    func loadIfNeeded() async {
        guard state.value == nil else { return }
        await load()
    }

    /// Always reloads (pull to refresh, retry). Keeps current content on screen meanwhile.
    func load() async {
        guard !state.isLoading else { return }
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await interactor.fetchItems())
        } catch is CancellationError {
            if state.isLoading { state = .idle }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func didSelect(_ item: ___VARIABLE_sceneName___Item) {
        router?.showItem(id: item.id)
    }
}
