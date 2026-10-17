//
//  EventListPresenter.swift
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
final class EventListPresenter {
    static let pageSize = 8

    private(set) var category: EventCategory
    /// Infinite scrolling state: items, phase (loading, loadingMore, failed...).
    let paginator: Paginator<Event>

    @ObservationIgnored private weak var router: (any EventListRouting)?

    init(category: EventCategory, interactor: any EventListInteracting, router: (any EventListRouting)?) {
        self.category = category
        self.router = router
        // The closure reads the CURRENT category, so a filter change + refresh just works.
        var currentCategory: () -> EventCategory = { category }
        self.paginator = Paginator(pageSize: Self.pageSize) { request in
            try await interactor.fetchEvents(category: currentCategory(), page: request)
        }
        currentCategory = { [weak self] in self?.category ?? category }
    }

    var title: String {
        category == .all ? L10n.Events.allTitle : L10n.category(category)
    }

    /// First appearance only: coming back from a detail keeps the list and scroll position.
    func loadIfNeeded() async {
        guard paginator.phase == .idle else { return }
        await load()
    }

    /// First page (also pull to refresh).
    func load() async {
        await paginator.loadFirstPage()
    }

    /// From each row's `onAppear`.
    func didShow(_ event: Event) async {
        await paginator.loadMoreIfNeeded(currentItem: event)
    }

    func didTapRetryMore() async {
        await paginator.loadNextPage()
    }

    func didSelectCategory(_ category: EventCategory) async {
        guard category != self.category else { return }
        self.category = category
        await paginator.loadFirstPage()
    }

    func didSelect(_ event: Event) {
        router?.showEvent(id: event.id)
    }
}
