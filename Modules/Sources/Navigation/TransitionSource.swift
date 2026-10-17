//
//  TransitionSource.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import SwiftUI

public extension View {
    /// Marks this view as the start of an `.expand(sourceID:)` transition:
    ///
    ///     EventCardView(event: event).transitionSource(id: "event.\(event.id)")
    ///     navigator.push(detail, transition: .expand(sourceID: "event.\(event.id)"))
    ///
    /// Measured only when the transition starts (no per-frame work while scrolling).
    func transitionSource(id: String) -> some View {
        background(TransitionAnchor(id: id))
    }
}

/// Invisible UIView with the same frame as the marked view.
private struct TransitionAnchor: UIViewRepresentable {
    let id: String

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        TransitionSourceRegistry.shared.register(id, view: view)
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        TransitionSourceRegistry.shared.register(id, view: view)
    }
}
