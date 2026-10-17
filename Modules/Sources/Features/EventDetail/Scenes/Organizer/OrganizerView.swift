//
//  OrganizerView.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import DesignSystem
import Domain
import SwiftUI

struct OrganizerView: View {
    let presenter: OrganizerPresenter

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
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .failed(message):
            ErrorStateView(message: message) {
                Task { await presenter.load() }
            }
        case let .loaded(profile):
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.m.rawValue) {
                    Text(profile.name)
                        .font(.dsLargeTitle)
                    Text(L10n.Event.eventsCount(profile.events.count))
                        .font(.dsCallout)
                        .foregroundStyle(.textSecondary)
                    ForEach(Array(profile.events.enumerated()), id: \.element.id) { index, event in
                        Button { presenter.didSelect(event) } label: { EventRowView(event: event) }
                            .buttonStyle(.pressable)
                            .staggeredAppear(index: index)
                    }
                }
                .pageMargin()
                .padding(.vertical, .m)
                .readableWidth()
            }
        }
    }
}

#Preview {
    OrganizerBuilder.build(eventID: "1", router: PreviewRouter.shared, interactor: PreviewInteractor())
        .asPreview()
}

private final class PreviewRouter: OrganizerRouting {
    /// Kept alive: presenters hold their router weakly.
    static let shared = PreviewRouter()

    func showEvent(id: String) {}
}

private struct PreviewInteractor: OrganizerInteracting {
    func fetchProfile() async throws -> OrganizerProfile {
        OrganizerProfile(name: "FA Thailand", events: Event.samples)
    }
}
