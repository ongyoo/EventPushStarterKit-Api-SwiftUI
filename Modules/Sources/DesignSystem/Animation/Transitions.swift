//
//  Transitions.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import SwiftUI

/// Insert / remove transitions for `if` / `switch` content:
///
///     if showBanner {
///         BannerView().transition(.dsSlideDown)
///     }
public extension AnyTransition {
    /// Fade + slight scale. Default for content swaps (loading -> loaded).
    static var dsScaleFade: AnyTransition { .opacity.combined(with: .scale(scale: 0.96)) }
    /// From the bottom with fade (toasts, bottom bars).
    static var dsSlideUp: AnyTransition { .move(edge: .bottom).combined(with: .opacity) }
    /// From the top with fade (banners, inline errors).
    static var dsSlideDown: AnyTransition { .move(edge: .top).combined(with: .opacity) }
    /// Push-like: in from trailing, out to leading (step-by-step flows).
    static var dsPush: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
}

/// Text that rolls its digits when the number changes (prices, counters).
///
///     AnimatedNumberText(value: cart.total, format: .currency(code: "THB"))
public struct AnimatedNumberText<F: FormatStyle>: View where F.FormatInput == Double, F.FormatOutput == String {
    private let value: Double
    private let format: F

    /// `AnimatedNumberText(value: price, format: .currency(code: "THB"))`
    public init(value: Double, format: F) {
        self.value = value
        self.format = format
    }

    public var body: some View {
        Text(value, format: format)
            .contentTransition(.numericText(value: value))
            .animation(.dsSpring, value: value)
    }
}
