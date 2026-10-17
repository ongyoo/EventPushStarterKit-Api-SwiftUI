//
//  DynamicScreenScreen.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import DesignSystem
import LiquidGlassKit
import ServerDrivenUI
import SwiftUI

/// Loading / error / the server-driven content. The title comes from the JSON.
struct DynamicScreenScreen: View {
    let presenter: DynamicScreenPresenter
    let showsClose: Bool

    var body: some View {
        content
            .tint(.brandPrimary)
            .navigationTitle(presenter.state.value?.title ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showsClose {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(L10n.tr("nav.close")) { presenter.perform(.dismiss) }
                    }
                }
            }
            .task { await presenter.loadIfNeeded() }
            .refreshable { await presenter.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch presenter.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .failed(message):
            ErrorStateView(message: message) { Task { await presenter.load() } }
        case let .loaded(screen):
            DynamicScreenView(screen: screen, registry: AppComponents.registry) { action in
                presenter.perform(action)
            }
            .id(presenter.revision)
        }
    }
}
