//
//  NotificationPresenter.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Foundation

/// Turns user actions into interactor calls and results into view updates.
@MainActor
final class NotificationPresenter: NotificationPresenting {
    weak var view: (any NotificationViewInput)?
    private weak var router: (any NotificationRouting)?
    private let interactor: any NotificationInteracting
    /// Cancels in-flight work when the presenter (= the screen) is released.
    private let tasks = TaskBag()
    private(set) var items: [NotificationItem] = []

    init(interactor: any NotificationInteracting, router: (any NotificationRouting)?) {
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
        guard let eventID = items[safe: index]?.eventID else { return }
        router?.openEvent(id: eventID)
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
