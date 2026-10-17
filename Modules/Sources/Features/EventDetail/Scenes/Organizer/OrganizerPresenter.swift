//
//  OrganizerPresenter.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Domain
import Foundation
import Observation

@MainActor
@Observable
final class OrganizerPresenter {
    private(set) var state: Loadable<OrganizerProfile> = .idle

    @ObservationIgnored private let interactor: any OrganizerInteracting
    @ObservationIgnored private weak var router: (any OrganizerRouting)?

    init(interactor: any OrganizerInteracting, router: (any OrganizerRouting)?) {
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
            state = .loaded(try await interactor.fetchProfile())
        } catch is CancellationError {
            if state.isLoading { state = .idle }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func didSelect(_ event: Event) {
        router?.showEvent(id: event.id)
    }
}
