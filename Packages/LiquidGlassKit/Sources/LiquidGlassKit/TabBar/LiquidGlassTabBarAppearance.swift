//
//  LiquidGlassTabBarAppearance.swift
//  LiquidGlassKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import UIKit

/// Everything about how the glass tab bar looks and moves, in one value.
/// Start from a preset, change what you need, assign it (live, animated):
///
///     var look = LiquidGlassTabBarAppearance.default
///     look.selection.style = .tint
///     look.item.showsTitles = false
///     tabs.appearance = look
///
/// Or in one go:
///
///     tabs.appearance = .tinted.with { $0.bar.itemWidth = 72 }
public struct LiquidGlassTabBarAppearance {
    public var bar = Bar()
    public var glass = Glass()
    public var selection = Selection()
    public var item = Item()
    public var droplet = Droplet()
    /// Selection haptic while sliding across tabs.
    public var haptics = true

    public init() {}

    /// A copy with changes: `.default.with { $0.selection.style = .dot }`.
    public func with(_ change: (inout LiquidGlassTabBarAppearance) -> Void) -> LiquidGlassTabBarAppearance {
        var copy = self
        change(&copy)
        return copy
    }

    // MARK: - Parts

    /// Size and position of the floating bar.
    public struct Bar {
        public var height: CGFloat = 62
        /// Width of one tab. The bar fits its tabs, up to the screen width minus `horizontalMargin`.
        public var itemWidth: CGFloat = 88
        /// `true`: always as wide as the screen allows.
        public var fillsWidth = false
        public var horizontalMargin: CGFloat = 16
        /// Space under the bar. `nil` = like iOS 26 (just above the home indicator).
        public var bottomSpacing: CGFloat?
        /// Space between the glass edge and the tabs.
        public var contentInset: CGFloat = 4
        /// `nil` = capsule.
        public var cornerRadius: CGFloat?
        /// Diameter of the minimized bar.
        public var minimizedSize: CGFloat = 54
        public init() {}
    }

    /// The glass material of the bar.
    public struct Glass {
        public var effects: LiquidGlassView.Effects = .all
        /// Tinted glass (e.g. brand color). `nil` = neutral.
        public var tint: UIColor?
        /// No frost: see-through glass with rim light only.
        public var isClear = false
        /// How much the rim magnifies the content behind (1 = none).
        public var refraction: CGFloat = 1.16
        public var shadowOpacity: Float?
        public init() {}
    }

    /// What marks the selected tab.
    public struct Selection {
        public enum Style: Sendable, Equatable, CaseIterable {
            /// Raised glass pill with a rim light (default).
            case glass
            /// Soft pill in the accent color.
            case tint
            /// Accent-filled pill, white content.
            case solid
            /// Short line under the tab.
            case underline
            /// Small dot under the tab.
            case dot
            /// Color change only.
            case none
        }

        /// How the indicator moves to a new tab.
        public enum Animation: Sendable, Equatable {
            /// Stretches over both tabs, then springs into place.
            case liquid
            case spring
            case none
        }

        public var style: Style = .glass
        /// Indicator color. `nil` = the bar's `tintColor` (`tabBar.tintColor`).
        public var color: UIColor?
        /// Indicator inset inside a tab (pill styles).
        public var inset: UIEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        /// `nil` = capsule.
        public var cornerRadius: CGFloat?
        public var animation: Animation = .liquid
        /// Icon squash-and-stretch when a tab becomes selected.
        public var bouncesIcon = true
        public init() {}
    }

    /// Icon, title and badge of each tab.
    public struct Item {
        public var iconPointSize: CGFloat = 20
        public var iconWeight: UIImage.SymbolWeight = .medium
        public var titleFont: UIFont = .systemFont(ofSize: 10, weight: .semibold)
        public var showsTitles = true
        public var spacing: CGFloat = 2
        /// `nil` = the bar's `tintColor` (white with `.solid` selection).
        public var selectedColor: UIColor?
        public var normalColor: UIColor = .label
        /// Use `tabBarItem.selectedImage` when selected (if set).
        public var usesSelectedImage = true
        public var badgeColor: UIColor = .systemRed
        public var badgeTextColor: UIColor = .white
        public init() {}
    }

    /// The glass lens that carries the selection while touching (iOS 26).
    public struct Droplet {
        /// `false`: taps select directly, no lens.
        public var isEnabled = true
        /// How much the lens enlarges the icons under it.
        public var magnification: CGFloat = 1.18
        /// How much bigger than the pill the lifted lens is.
        public var lift = CGSize(width: 12, height: 12)
        /// Maximum stretch at high speed (0.3 = 30% longer).
        public var maxStretch: CGFloat = 0.3
        public init() {}
    }

    // MARK: - Presets

    /// Like iOS 26, with a raised glass selection.
    public static var `default`: LiquidGlassTabBarAppearance { LiquidGlassTabBarAppearance() }

    /// Accent-tinted selection pill.
    public static var tinted: LiquidGlassTabBarAppearance { .default.with { $0.selection.style = .tint } }

    /// Accent-filled selection, white icon and title.
    public static var solid: LiquidGlassTabBarAppearance { .default.with { $0.selection.style = .solid } }

    /// Icons only, a dot under the selected one.
    public static var minimal: LiquidGlassTabBarAppearance {
        .default.with {
            $0.selection.style = .dot
            $0.item.showsTitles = false
            $0.item.iconPointSize = 22
            $0.bar.height = 56
            $0.bar.itemWidth = 72
        }
    }

    /// Underline under the selected tab, no lens.
    public static var underline: LiquidGlassTabBarAppearance {
        .default.with {
            $0.selection.style = .underline
            $0.droplet.isEnabled = false
        }
    }

    // MARK: - Resolved values

    /// Color of the selected icon and title.
    func selectedItemColor(tint: UIColor) -> UIColor {
        if let color = item.selectedColor { return color }
        return selection.style == .solid ? .white : (selection.color ?? tint)
    }

    func indicatorColor(tint: UIColor) -> UIColor {
        selection.color ?? tint
    }
}
