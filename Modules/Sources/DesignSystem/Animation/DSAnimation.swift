//
//  DSAnimation.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import SwiftUI

/// Motion tokens. Use these instead of ad-hoc durations so the whole app
/// feels consistent:
///
///     withAnimation(.dsSpring) { isExpanded.toggle() }
///
/// Every helper in this folder respects the system "Reduce Motion" setting:
/// movement is replaced by a simple fade.
public extension Animation {
    /// 0.15s – taps, small state changes.
    static let dsQuick = Animation.easeOut(duration: 0.15)
    /// 0.3s – most transitions.
    static let dsStandard = Animation.easeInOut(duration: 0.3)
    /// 0.5s – large elements entering the screen.
    static let dsSlow = Animation.easeInOut(duration: 0.5)
    /// Natural spring for movement (cards, sheets, toggles).
    static let dsSpring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    /// Playful spring with overshoot (likes, badges, success).
    static let dsBouncy = Animation.spring(response: 0.35, dampingFraction: 0.55)
}

/// Timing constants for staggered animations.
public enum DSMotion {
    /// Delay between items of a staggered list.
    public static let staggerStep: Double = 0.05
    /// Cap so long lists don't wait forever for the last items.
    public static let maxStaggerDelay: Double = 0.4
    /// Only the first rows (the first screenful) animate in. Rows further down
    /// appear while scrolling and must NOT animate, or scrolling feels jerky.
    public static let maxStaggeredItems = 8
}
