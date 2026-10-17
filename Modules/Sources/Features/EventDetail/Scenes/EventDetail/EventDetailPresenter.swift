//
//  EventDetailPresenter.swift
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
final class EventDetailPresenter {
    private(set) var state: Loadable<Event> = .idle
    private(set) var isFavorite = false

    @ObservationIgnored private let interactor: any EventDetailInteracting
    @ObservationIgnored private weak var router: (any EventDetailRouting)?
    @ObservationIgnored private let analytics: any AnalyticsTracking

    init(
        interactor: any EventDetailInteracting,
        router: (any EventDetailRouting)?,
        analytics: any AnalyticsTracking = Container.shared.analytics()
    ) {
        self.interactor = interactor
        self.router = router
        self.analytics = analytics
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
            state = .loaded(try await interactor.fetchEvent())
            isFavorite = await interactor.isFavorite()
        } catch is CancellationError {
            if state.isLoading { state = .idle }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func didTapFavorite() async {
        guard let event = state.value else { return }
        isFavorite.toggle() // optimistic: the heart reacts instantly
        do {
            isFavorite = try await interactor.toggleFavorite(event)
            analytics.track(.favoriteToggled(eventID: event.id, isFavorite: isFavorite))
        } catch {
            isFavorite.toggle()
        }
    }

    func didTapOrganizer() {
        guard let event = state.value else { return }
        router?.showOrganizer(ofEventID: event.id)
    }
}
