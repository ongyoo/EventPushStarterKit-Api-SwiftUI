___FILEHEADER___

import DesignSystem
import SwiftUI

/// Pure rendering of `presenter.state`. No business logic, no navigation.
struct ___VARIABLE_sceneName___View: View {
    let presenter: ___VARIABLE_sceneName___Presenter

    var body: some View {
        content
            .adaptiveLayout()
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
        case let .loaded(items) where items.isEmpty:
            EmptyStateView("Nothing here yet")
        case let .loaded(items):
            List(items) { item in
                Button(item.title) { presenter.didSelect(item) }
            }
            .refreshable { await presenter.load() }
        }
    }
}

#Preview {
    ___VARIABLE_sceneName___View(
        presenter: ___VARIABLE_sceneName___Presenter(interactor: ___VARIABLE_sceneName___Interactor(), router: nil)
    )
}
