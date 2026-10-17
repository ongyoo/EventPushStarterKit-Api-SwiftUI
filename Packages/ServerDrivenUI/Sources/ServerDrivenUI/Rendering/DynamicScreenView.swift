//
//  DynamicScreenView.swift
//  ServerDrivenUI
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import LiquidGlassKit
import SwiftUI

/// Renders a `DynamicScreen`: scrolling body, optional floating glass toolbar.
///
///     DynamicScreenView(screen: screen) { action in
///         router.perform(action)            // deep links, analytics, other screens
///     }
public struct DynamicScreenView: View {
    private let screen: DynamicScreen
    private let registry: DynamicComponentRegistry
    private let onAction: @MainActor (DynamicAction) -> Void
    @State private var state: DynamicScreenState

    public init(
        screen: DynamicScreen,
        registry: DynamicComponentRegistry = .standard,
        onAction: @escaping @MainActor (DynamicAction) -> Void
    ) {
        self.screen = screen
        self.registry = registry
        self.onAction = onAction
        self._state = State(initialValue: DynamicScreenState(screen.state))
    }

    private var context: DynamicRenderContext {
        DynamicRenderContext(state: state, registry: registry, perform: perform)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                context.render(screen.body)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, screen.toolbar.isEmpty ? 0 : 96)
        }
        .liquidScrollEdge()
        .overlay(alignment: .bottom) {
            if !screen.toolbar.isEmpty {
                LiquidGlassToolbar {
                    context.render(screen.toolbar)
                }
                // Clear of floating bars and raised buttons below.
                .padding(.bottom, 28)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: state.values)
    }

    /// State actions run here (instant, offline); the rest go to the app.
    func perform(_ action: DynamicAction) {
        switch action {
        case let .setState(key, value):
            state[key] = value
        case let .toggleState(key):
            state[key] = .bool(!(state[key]?.bool ?? false))
        case let .sequence(actions):
            actions.forEach(perform)
        default:
            onAction(action)
        }
    }
}
