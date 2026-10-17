//
//  EventListView.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import DesignSystem
import Domain
import SwiftUI

struct EventListView: View {
    let presenter: EventListPresenter

    var body: some View {
        EventListContent(presenter: presenter)
            .adaptiveLayout()
            .background(Color.backgroundSecondary)
            .navigationTitle(presenter.title)
            .toolbar {
                Menu {
                    ForEach(EventCategory.allCases, id: \.self) { category in
                        Button(L10n.category(category), systemImage: category.iconName) {
                            Task { await presenter.didSelectCategory(category) }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
                .accessibilityLabel(L10n.Events.filter)
            }
            .task { await presenter.loadIfNeeded() }
    }
}

private struct EventListContent: View {
    let presenter: EventListPresenter
    @Environment(\.layoutClass) private var layout

    var body: some View {
        let paginator = presenter.paginator
        switch paginator.phase {
        case .idle:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loading where paginator.items.isEmpty:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .failed(message):
            ErrorStateView(message: message) {
                Task { await presenter.load() }
            }
        case .loaded where paginator.items.isEmpty:
            EmptyStateView(L10n.Home.emptyTitle, systemImage: "calendar", message: L10n.Events.emptyMessage)
        default:
            ScrollView {
                LazyVGrid(columns: .columns(layout.value(compact: 1, medium: 2, expanded: 3)), spacing: DS.Space.m.rawValue) {
                    ForEach(Array(paginator.items.enumerated()), id: \.element.id) { index, event in
                        Button { presenter.didSelect(event) } label: { EventRowView(event: event) }
                            .buttonStyle(.pressable)
                            // First page only: pages loaded while scrolling appear directly.
                            .staggeredAppear(index: index)
                            // Load more when the user gets close to the end.
                            .task { await presenter.didShow(event) }
                    }
                }
                .pageMargin()
                .padding(.top, .m)

                LoadMoreFooter(phase: paginator.phase) {
                    Task { await presenter.didTapRetryMore() }
                }
            }
            .refreshable { await presenter.load() }
        }
    }
}

#Preview {
    EventListBuilder.build(category: .all, router: PreviewRouter.shared, interactor: PreviewInteractor())
        .asPreview()
}

private final class PreviewRouter: EventListRouting {
    /// Kept alive: presenters hold their router weakly.
    static let shared = PreviewRouter()

    func showEvent(id: String) {}
}

private struct PreviewInteractor: EventListInteracting {
    func fetchEvents(category: EventCategory, page: PageRequest) async throws -> Page<Event> {
        .slice(Event.samples, page)
    }
}
