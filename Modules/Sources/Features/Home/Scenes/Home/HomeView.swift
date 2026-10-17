//
//  HomeView.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import DesignSystem
import Domain
import SwiftUI

struct HomeView: View {
    @Bindable var presenter: HomePresenter

    var body: some View {
        HomeScrollView(presenter: presenter)
            .adaptiveLayout()
            .background(Color.backgroundSecondary)
            .task { await presenter.loadIfNeeded() }
    }
}

private struct HomeScrollView: View {
    @Bindable var presenter: HomePresenter

    var body: some View {
        // Layout rule for smooth scrolling and stable state:
        // - Top part (header, search, categories, carousel) is a plain VStack: built
        //   once, never destroyed, so horizontal scroll positions are kept for free.
        // - Only the long list is lazy (rows are created as they come on screen).
        // - No programmatic scrolling: the UIScrollView keeps its own offset while the
        //   screen stays in the navigation stack.
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.m.rawValue) {
                HomeHeaderView(city: "Bangkok", onNotificationsTap: presenter.didTapNotifications)
                    .pageMargin()
                SearchBarView(text: $presenter.searchText)
                    .pageMargin()
                CategoryBarView(
                    categories: presenter.categories,
                    selected: presenter.selectedCategory,
                    onSelect: presenter.didSelectCategory
                )
                HomeContentView(presenter: presenter)
            }
            .animation(.dsStandard, value: presenter.state.isLoading)
            .padding(.vertical, .m)
            .readableWidth(1_200)
        }
        .scrollDismissesKeyboard(.interactively)
        .refreshable { await presenter.load() }
    }
}

/// Everything below the category bar.
private struct HomeContentView: View {
    @Bindable var presenter: HomePresenter

    var body: some View {
        switch presenter.state {
        case .idle, .loading:
            HomeLoadingView()
        case let .failed(message):
            ErrorStateView(message: message) {
                Task { await presenter.load() }
            }
        case let .loaded(content):
            SectionHeaderView(title: L10n.Home.popular) { presenter.didTapSeeAll() }
                .pageMargin()
            EventCarousel(events: content.featured, animated: presenter.animatesEntrance, onSelect: presenter.didSelectFeatured)

            SectionHeaderView(title: L10n.Home.upcoming) { presenter.didTapSeeAll() }
                .pageMargin()
            UpcomingList(presenter: presenter)
        }
    }
}

/// Upcoming events, capped (`HomePresenter.upcomingLimit`).
///
/// A plain `VStack`, not a `LazyVStack`: rows are built once, so scrolling does
/// no SwiftUI layout at all (measured: 0 dropped frames vs ~2% with lazy rows of
/// varying height). Unbounded lists belong in a paginated screen (Event List).
private struct UpcomingList: View {
    let presenter: HomePresenter
    @Environment(\.layoutClass) private var layout

    var body: some View {
        let upcoming = presenter.visibleUpcoming
        if upcoming.isEmpty {
            EmptyStateView(L10n.Home.emptyTitle, systemImage: "calendar.badge.exclamationmark", message: L10n.Home.emptyMessage)
        } else {
            let columns = layout.value(compact: 1, medium: 2, expanded: 3)
            VStack(alignment: .leading, spacing: DS.Space.m.rawValue) {
                ForEach(Array(EventRowGroup.make(upcoming, columns: columns).enumerated()), id: \.element.id) { index, group in
                    EventRowGroupView(group: group, columns: columns, onSelect: presenter.didSelectEvent)
                        .pageMargin()
                        .staggeredAppear(index: index, isEnabled: presenter.animatesEntrance)
                }
                let total = presenter.matchingUpcomingCount
                if total > upcoming.count {
                    Button(L10n.Home.seeAll(count: total), action: presenter.didTapSeeAll)
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                        .pageMargin()
                }
            }
        }
    }
}

#Preview {
    HomeBuilder.build(router: PreviewRouter.shared, interactor: PreviewInteractor())
        .asPreview()
}

private final class PreviewRouter: HomeRouting {
    /// Kept alive: presenters hold their router weakly.
    static let shared = PreviewRouter()

    func showFeaturedEvent(id: String) {}
    func showEventDetail(id: String) {}
    func showAllEvents(category: EventCategory) {}
    func showNotifications() {}
}

private struct PreviewInteractor: HomeInteracting {
    func loadContent() async throws -> HomeContent {
        HomeContent(featured: Event.samples, upcoming: Event.samples)
    }
}
