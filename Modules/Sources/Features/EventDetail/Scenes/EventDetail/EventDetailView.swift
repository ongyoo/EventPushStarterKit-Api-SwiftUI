//
//  EventDetailView.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import DesignSystem
import Domain
import SwiftUI

struct EventDetailView: View {
    let presenter: EventDetailPresenter

    var body: some View {
        content
            .adaptiveLayout()
            .background(Color.backgroundSecondary)
            .task { await presenter.loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        switch presenter.state {
        case .idle, .loading:
            EventDetailContent(event: .sample, isFavorite: false, onFavoriteTap: {}, onOrganizerTap: {})
                .skeleton()
        case let .failed(message):
            ErrorStateView(message: message) {
                Task { await presenter.load() }
            }
        case let .loaded(event):
            EventDetailContent(
                event: event,
                isFavorite: presenter.isFavorite,
                onFavoriteTap: { Task { await presenter.didTapFavorite() } },
                onOrganizerTap: presenter.didTapOrganizer
            )
        }
    }
}

/// Image + info. Side by side on iPad / landscape, stacked on iPhone.
private struct EventDetailContent: View {
    let event: Event
    let isFavorite: Bool
    let onFavoriteTap: () -> Void
    let onOrganizerTap: () -> Void
    @Environment(\.layoutClass) private var layout

    var body: some View {
        ScrollView {
            AdaptiveStack(horizontalFrom: .expanded, spacing: .l) {
                RemoteImage(url: event.thumbnailURL)
                    .aspectRatio(4 / 3, contentMode: .fit)
                    .frame(maxWidth: layout == .expanded ? 480 : .infinity)
                    .cornerRadius(layout == .compact ? .s : .l)
                    .overlay(alignment: .topTrailing) {
                        FavoriteButton(isFavorite: isFavorite, action: onFavoriteTap)
                            .padding(.s)
                    }

                VStack(alignment: .leading, spacing: DS.Space.m.rawValue) {
                    Text(event.title)
                        .font(.dsLargeTitle)
                        .foregroundStyle(.textPrimary)
                    EventMetadataCard(event: event)
                    OrganizerRowView(name: event.organizerName, action: onOrganizerTap)
                    AboutSectionView(text: event.description)
                }
            }
            .pageMargin()
            .padding(.vertical, .m)
            .readableWidth(1_100)
        }
    }
}

/// Heart with a "pop" each time it changes.
private struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.title2)
                .foregroundStyle(isFavorite ? Color.pink : .white)
                .frame(width: DS.Size.minTapTarget, height: DS.Size.minTapTarget)
                .background(Circle().fill(.black.opacity(0.35)))
                .pop(trigger: isFavorite)
        }
        .accessibilityLabel(isFavorite ? L10n.tr("event.favorite.remove") : L10n.tr("event.favorite.add"))
    }
}

#Preview {
    EventDetailBuilder.build(eventID: "1", router: PreviewRouter.shared, interactor: PreviewInteractor())
        .asPreview()
}

private final class PreviewRouter: EventDetailRouting {
    /// Kept alive: presenters hold their router weakly.
    static let shared = PreviewRouter()

    func showOrganizer(ofEventID eventID: String) {}
}

private struct PreviewInteractor: EventDetailInteracting {
    func fetchEvent() async throws -> Event { .sample }
    func isFavorite() async -> Bool { true }
    func toggleFavorite(_ event: Event) async throws -> Bool { false }
}
