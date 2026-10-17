//
//  LiquidGlassContainer.swift
//  LiquidGlassKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import SwiftUI

/// Groups glass shapes so they blend and morph into each other, like iOS 26's
/// `GlassEffectContainer`. Give each piece `.liquidGlassID(_:in:)` and insert
/// or remove pieces with animation: they flow out of / back into each other.
///
///     @Namespace var glass
///     LiquidGlassContainer(spacing: 12) {
///         HStack {
///             Button("Edit") { ... }.liquidGlassButton().liquidGlassID("edit", in: glass)
///             if expanded {
///                 Button("Share") { ... }.liquidGlassButton().liquidGlassID("share", in: glass)
///             }
///         }
///     }
///
/// iOS 17–18 approximate the morph with `matchedGeometryEffect`.
public struct LiquidGlassContainer<Content: View>: View {
    private let spacing: CGFloat?
    private let content: Content

    public init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        if LiquidGlass.isSystemDesign, #available(iOS 26, *) {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            content
        }
    }
}

public extension View {
    /// Identity of a glass piece for morphing inside `LiquidGlassContainer`.
    @ViewBuilder
    func liquidGlassID<ID: Hashable & Sendable>(_ id: ID, in namespace: Namespace.ID) -> some View {
        if LiquidGlass.isSystemDesign, #available(iOS 26, *) {
            glassEffectID(id, in: namespace)
        } else {
            matchedGeometryEffect(id: id, in: namespace)
        }
    }
}
