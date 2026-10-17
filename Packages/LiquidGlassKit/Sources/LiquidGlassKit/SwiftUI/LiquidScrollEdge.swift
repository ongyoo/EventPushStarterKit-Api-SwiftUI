//
//  LiquidScrollEdge.swift
//  LiquidGlassKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import SwiftUI

public extension View {
    /// Softly blurs content as it scrolls under the top/bottom edges, so bars
    /// and floating glass stay readable (iOS 26 "scroll edge effect").
    /// iOS 26: `scrollEdgeEffectStyle(.soft)`. iOS 17–18: a fading material strip.
    ///
    ///     ScrollView { ... }.liquidScrollEdge()
    @ViewBuilder
    func liquidScrollEdge(_ edges: VerticalEdge.Set = .all) -> some View {
        if LiquidGlass.isSystemDesign, #available(iOS 26, *) {
            scrollEdgeEffectStyle(.soft, for: Edge.Set(edges))
        } else {
            overlay(alignment: .top) {
                if edges.contains(.top) { EdgeFade(edge: .top) }
            }
            .overlay(alignment: .bottom) {
                if edges.contains(.bottom) { EdgeFade(edge: .bottom) }
            }
        }
    }
}

private extension Edge.Set {
    init(_ edges: VerticalEdge.Set) {
        var set: Edge.Set = []
        if edges.contains(.top) { set.insert(.top) }
        if edges.contains(.bottom) { set.insert(.bottom) }
        self = set
    }
}

/// Material that fades out away from the edge (covers the safe area too).
private struct EdgeFade: View {
    let edge: VerticalEdge

    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .mask(
                LinearGradient(
                    colors: [.black, .black.opacity(0.6), .clear],
                    startPoint: edge == .top ? .top : .bottom,
                    endPoint: edge == .top ? .bottom : .top
                )
            )
            .frame(height: 28)
            .ignoresSafeArea(edges: edge == .top ? .top : .bottom)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
