//
//  AppearAnimation.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import SwiftUI

/// How a view enters the screen.
public enum AppearStyle: Sendable, CaseIterable, Hashable {
    case fade
    case slideUp
    case slideFromLeading
    case slideFromTrailing
    case scale
    case blur

    public static let allCases: [AppearStyle] = [.fade, .slideUp, .slideFromLeading, .slideFromTrailing, .scale, .blur]

    /// Display name (gallery, debug menus).
    public var name: String {
        switch self {
        case .fade: "Fade"
        case .slideUp: "Slide up"
        case .slideFromLeading: "Slide from leading"
        case .slideFromTrailing: "Slide from trailing"
        case .scale: "Scale"
        case .blur: "Blur"
        }
    }
}

public extension View {
    /// Animates the view the first time it appears.
    ///
    ///     EventRowView(event: event)
    ///         .appearAnimation(.slideUp)
    /// - Parameter isEnabled: `false` shows the view directly (e.g. when coming back
    ///   to a screen: entrance animations should play once, not on every appearance).
    func appearAnimation(
        _ style: AppearStyle = .fade,
        delay: Double = 0,
        animation: Animation = .dsSpring,
        isEnabled: Bool = true
    ) -> some View {
        modifier(AppearAnimationModifier(style: style, delay: delay, animation: animation, isEnabled: isEnabled))
    }

    /// Staggered entrance for list items: each item starts a bit later.
    ///
    ///     ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
    ///         EventRowView(event: event).staggeredAppear(index: index)
    ///     }
    ///
    /// Only the first `DSMotion.maxStaggeredItems` rows animate; later rows (shown
    /// while scrolling) appear directly so scrolling stays smooth.
    func staggeredAppear(index: Int, style: AppearStyle = .slideUp, isEnabled: Bool = true) -> some View {
        appearAnimation(
            style,
            delay: min(Double(index) * DSMotion.staggerStep, DSMotion.maxStaggerDelay),
            isEnabled: isEnabled && index < DSMotion.maxStaggeredItems
        )
    }
}

private struct AppearAnimationModifier: ViewModifier {
    let style: AppearStyle
    let delay: Double
    let animation: Animation
    let isEnabled: Bool

    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let hidden = isEnabled && !isVisible
        let moves = !reduceMotion
        content
            .opacity(hidden ? 0 : 1)
            .offset(x: hidden && moves ? offsetX : 0, y: hidden && moves ? offsetY : 0)
            .scaleEffect(hidden && moves && style == .scale ? 0.85 : 1)
            .blur(radius: hidden && style == .blur ? 8 : 0)
            .onAppear {
                guard !isVisible else { return }
                withAnimation((reduceMotion ? .dsQuick : animation).delay(delay)) {
                    isVisible = true
                }
            }
    }

    private var offsetX: CGFloat {
        switch style {
        case .slideFromLeading: -40
        case .slideFromTrailing: 40
        default: 0
        }
    }

    private var offsetY: CGFloat {
        style == .slideUp ? 24 : 0
    }
}
