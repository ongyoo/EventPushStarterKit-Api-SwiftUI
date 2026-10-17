//
//  HomePresenter.swift
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
final class HomePresenter {
    private(set) var state: Loadable<HomeContent> = .idle
    var selectedCategory: EventCategory = .all
    var searchText = ""
    /// Entrance animations run on the first appearance only.
    private(set) var animatesEntrance = true

    /// Content older than this is refreshed silently when the screen reappears.
    static let staleAfter: TimeInterval = 5 * 60
    @ObservationIgnored private var loadedAt: Date?

    let categories = EventCategory.allCases

    @ObservationIgnored private let interactor: any HomeInteracting
    @ObservationIgnored private weak var router: (any HomeRouting)?
    @ObservationIgnored private let analytics: any AnalyticsTracking

    init(
        interactor: any HomeInteracting,
        router: (any HomeRouting)?,
        analytics: any AnalyticsTracking = Container.shared.analytics()
    ) {
        self.interactor = interactor
        self.router = router
        self.analytics = analytics
    }

    /// Home is a summary: it shows at most this many upcoming events (built
    /// once, no lazy layout while scrolling). The full list is the paginated
    /// Event List behind "See all".
    static let upcomingLimit = 20

    /// Upcoming events after category + search filters, capped at `upcomingLimit`.
    var visibleUpcoming: [Event] {
        Array(matchingUpcoming.prefix(Self.upcomingLimit))
    }

    /// Number of matching events, including those not shown on Home.
    var matchingUpcomingCount: Int {
        matchingUpcoming.count
    }

    private var matchingUpcoming: [Event] {
        guard let upcoming = state.value?.upcoming else { return [] }
        let query = searchText.trimmingCharacters(in: .whitespaces)
        return upcoming.filter { event in
            (selectedCategory == .all || event.category == selectedCategory)
                && (query.isEmpty || event.title.localizedCaseInsensitiveContains(query))
        }
    }

    /// Called on every appearance (`.task {}`): loads the first time only.
    /// Coming back keeps content, filters and scroll position; stale content
    /// (> `staleAfter`) is refreshed in the background without clearing the screen.
    func loadIfNeeded(now: Date = .now) async {
        if let loadedAt, state.value != nil {
            animatesEntrance = false
            guard now.timeIntervalSince(loadedAt) > Self.staleAfter else { return }
        }
        await load()
    }

    /// Always reloads (pull to refresh, retry). Keeps the current content on screen while loading.
    func load() async {
        guard !state.isLoading else { return }
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await interactor.loadContent())
            loadedAt = .now
            endEntranceAnimationsSoon()
        } catch is CancellationError {
            if state.isLoading { state = .idle }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// The entrance plays once, on the first render. LazyVStack recreates rows when
    /// they scroll back into view: they must not animate again.
    private func endEntranceAnimationsSoon() {
        guard animatesEntrance else { return }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            self?.animatesEntrance = false
        }
    }

    func didSelectCategory(_ category: EventCategory) {
        guard category != selectedCategory else { return }
        selectedCategory = category
        analytics.track(.categorySelected(category))
    }

    func didSelectFeatured(_ event: Event) {
        analytics.track(.eventSelected(id: event.id, source: .popular))
        router?.showFeaturedEvent(id: event.id)
    }

    func didSelectEvent(_ event: Event) {
        analytics.track(.eventSelected(id: event.id, source: .upcoming))
        router?.showEventDetail(id: event.id)
    }

    func didTapSeeAll() {
        analytics.track(.seeAllTapped(category: selectedCategory))
        router?.showAllEvents(category: selectedCategory)
    }

    func didTapNotifications() {
        router?.showNotifications()
    }
}
