//
//  Effects.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import SwiftUI

public extension View {
    /// Horizontal shake, e.g. on validation error. Runs each time `trigger` changes.
    ///
    ///     TextField("PIN", text: $pin).shake(trigger: attempts)
    func shake<T: Equatable & Sendable>(trigger: T) -> some View {
        modifier(ShakeModifier(trigger: trigger))
    }

    /// Gentle repeating scale, e.g. "live" badge or call-to-action.
    func pulse(_ isActive: Bool = true) -> some View {
        modifier(PulseModifier(isActive: isActive))
    }

    /// Slow up/down float, e.g. empty-state illustrations.
    func floating(_ isActive: Bool = true, distance: CGFloat = 6) -> some View {
        modifier(FloatingModifier(isActive: isActive, distance: distance))
    }

    /// Light sweep across the view (loading placeholders, premium badges).
    func shimmer(_ isActive: Bool = true) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }

    /// One-shot "pop" scale each time `trigger` changes (like, add to cart).
    func pop<T: Equatable & Sendable>(trigger: T) -> some View {
        modifier(PopModifier(trigger: trigger))
    }
}

/// Button that shrinks while pressed. Feels responsive, costs nothing.
///
///     Button("Buy") { ... }.buttonStyle(.pressable)
public struct PressableButtonStyle: ButtonStyle {
    private let scale: CGFloat

    /// `.buttonStyle(.pressable)` or `PressableButtonStyle(scale: 0.9)`.
    public init(scale: CGFloat = 0.96) {
        self.scale = scale
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.dsQuick, value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}

// MARK: - Modifiers

private struct ShakeModifier<T: Equatable & Sendable>: ViewModifier {
    let trigger: T
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let reduceMotion = reduceMotion // read once on the main actor
        return content.keyframeAnimator(initialValue: CGFloat.zero, trigger: trigger) { view, offset in
            view.offset(x: reduceMotion ? 0 : offset)
        } keyframes: { _ in
            KeyframeTrack {
                SpringKeyframe(-10, duration: 0.07)
                SpringKeyframe(10, duration: 0.07)
                SpringKeyframe(-6, duration: 0.07)
                SpringKeyframe(6, duration: 0.07)
                SpringKeyframe(0, duration: 0.1)
            }
        }
    }
}

private struct PulseModifier: ViewModifier {
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if isActive && !reduceMotion {
            content.phaseAnimator([1.0, 1.06]) { view, scale in
                view.scaleEffect(scale)
            } animation: { _ in .easeInOut(duration: 0.8) }
        } else {
            content
        }
    }
}

private struct FloatingModifier: ViewModifier {
    let isActive: Bool
    let distance: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if isActive && !reduceMotion {
            content.phaseAnimator([0, -distance]) { view, offset in
                view.offset(y: offset)
            } animation: { _ in .easeInOut(duration: 1.6) }
        } else {
            content
        }
    }
}

private struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = -1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if isActive && !reduceMotion {
            content
                .overlay {
                    GeometryReader { proxy in
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.5), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: proxy.size.width * 0.6)
                        .offset(x: phase * proxy.size.width * 1.6)
                    }
                    .allowsHitTesting(false)
                }
                .mask(content)
                .onAppear {
                    withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        } else {
            content
        }
    }
}

private struct PopModifier<T: Equatable & Sendable>: ViewModifier {
    let trigger: T
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let reduceMotion = reduceMotion // read once on the main actor
        return content.keyframeAnimator(initialValue: CGFloat(1), trigger: trigger) { view, scale in
            view.scaleEffect(reduceMotion ? 1 : scale)
        } keyframes: { _ in
            KeyframeTrack {
                SpringKeyframe(1.25, duration: 0.12)
                SpringKeyframe(1, duration: 0.25, spring: .bouncy)
            }
        }
    }
}
