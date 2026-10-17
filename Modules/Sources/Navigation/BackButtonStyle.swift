//
//  BackButtonStyle.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Foundation
import LiquidGlassKit
import UIKit

/// How the back button of a navigation stack looks.
///
/// iOS 26 draws the back button as Liquid Glass, which usually already fits.
/// Earlier versions show the classic chevron + previous title. Wrap a style in
/// `.belowIOS26(...)` to restyle only the older systems:
///
///     Navigator.defaultBackButton = .belowIOS26(.circle())     // whole app (AppAssembly)
///     HostingController(rootView: v, backButton: .minimal)    // one screen
///
/// Only the look changes. The system button is kept (its image and title are
/// replaced), so tap, swipe back, VoiceOver ("Back"), the long-press history
/// menu, right-to-left layout and `onPop` keep working. Never replace the
/// button with `leftBarButtonItem`: that loses all of the above.
@MainActor
public struct BackButtonStyle {
    /// Draws the indicator for the current light/dark traits.
    typealias IndicatorMaker = @MainActor (UITraitCollection) -> UIImage?

    /// `true` = UIKit's own button, untouched.
    let isSystem: Bool
    /// Title mode for the item *below* the shown screen (UIKit builds the
    /// back button from the previous screen's item).
    let titleMode: UINavigationItem.BackButtonDisplayMode
    /// Title color. `nil` = the bar's `tintColor`.
    let tint: UIColor?
    /// `nil` = system chevron.
    let indicator: IndicatorMaker?

    init(
        isSystem: Bool = false,
        titleMode: UINavigationItem.BackButtonDisplayMode = .default,
        tint: UIColor? = nil,
        indicator: IndicatorMaker? = nil
    ) {
        self.isSystem = isSystem
        self.titleMode = titleMode
        self.tint = tint
        self.indicator = indicator
    }

    // MARK: - Styles

    /// UIKit's default (Liquid Glass on iOS 26, chevron + title before).
    public static var system: BackButtonStyle { BackButtonStyle(isSystem: true) }

    /// System chevron, no title.
    public static var minimal: BackButtonStyle { BackButtonStyle(titleMode: .minimal) }

    /// System chevron + "Back" instead of the previous screen's title.
    public static var generic: BackButtonStyle { BackButtonStyle(titleMode: .generic) }

    /// An SF Symbol as the indicator.
    /// - Parameters:
    ///   - tint: indicator and title color. `nil` follows the bar's `tintColor`.
    ///   - showsTitle: `true` keeps the previous screen's title next to it.
    ///
    ///       .chevron(symbol: "arrow.left", tint: .brandPrimary)
    public static func chevron(
        symbol: String = "chevron.backward",
        weight: UIImage.SymbolWeight = .semibold,
        tint: UIColor? = nil,
        showsTitle: Bool = false
    ) -> BackButtonStyle {
        let configuration = UIImage.SymbolConfiguration(pointSize: 18, weight: weight)
        var image = UIImage(systemName: symbol, withConfiguration: configuration)
        if let tint {
            image = image?.withTintColor(tint, renderingMode: .alwaysOriginal)
        }
        return BackButtonStyle(titleMode: showsTitle ? .default : .minimal, tint: tint) { _ in image }
    }

    /// Chevron on a round background, no title. Reads well on top of photos
    /// (transparent bars) and looks close to iOS 26 on older systems.
    /// Colors may be dynamic: the navigator redraws it when light/dark changes.
    ///
    ///     .circle(foreground: .white, background: .black.withAlphaComponent(0.4), border: nil)
    public static func circle(
        symbol: String = "chevron.backward",
        foreground: UIColor = .label,
        background: UIColor = .tertiarySystemBackground,
        border: UIColor? = .separator,
        diameter: CGFloat = 32
    ) -> BackButtonStyle {
        BackButtonStyle(titleMode: .minimal) { traits in
            BackIndicatorRenderer.circle(
                symbol: symbol,
                foreground: foreground.resolvedColor(with: traits),
                background: background.resolvedColor(with: traits),
                border: border?.resolvedColor(with: traits),
                diameter: diameter
            )
        }
    }

    /// Any image (asset from your design). Template images follow the bar's
    /// `tintColor`; use `.withRenderingMode(.alwaysOriginal)` to keep its colors.
    public static func image(_ image: UIImage, showsTitle: Bool = false) -> BackButtonStyle {
        BackButtonStyle(titleMode: showsTitle ? .default : .minimal) { _ in image }
    }

    /// `style` before iOS 26, `.system` (Liquid Glass) from iOS 26.
    /// Apps that opt out of the new design (`UIDesignRequiresCompatibility`
    /// in Info.plist) still look like iOS 18, so they get `style` too.
    public static func belowIOS26(_ style: BackButtonStyle) -> BackButtonStyle {
        select(style, systemHasGlassBackButton: systemHasGlassBackButton)
    }

    static func select(_ style: BackButtonStyle, systemHasGlassBackButton: Bool) -> BackButtonStyle {
        systemHasGlassBackButton ? .system : style
    }

    static var systemHasGlassBackButton: Bool { LiquidGlass.isSystemDesign }

    // MARK: - Applying

    /// A copy of `appearance` with this style's indicator and title color.
    func applied(to appearance: UINavigationBarAppearance, traits: UITraitCollection) -> UINavigationBarAppearance {
        let copy = appearance.copy()
        if isSystem {
            // nil + nil restores the system chevron.
            copy.setBackIndicatorImage(nil, transitionMaskImage: nil)
            copy.backButtonAppearance = UIBarButtonItemAppearance(style: .plain)
            return copy
        }
        let image = indicator?(traits)
        copy.setBackIndicatorImage(image, transitionMaskImage: image)
        if let tint {
            copy.backButtonAppearance.normal.titleTextAttributes[.foregroundColor] = tint
        }
        return copy
    }

    /// Bar-wide: every screen of the stack (unless one overrides it).
    func apply(to bar: UINavigationBar, traits: UITraitCollection) {
        guard !isSystem else { return }
        let scrollEdge = bar.scrollEdgeAppearance ?? Self.transparent(bar.standardAppearance)
        bar.standardAppearance = applied(to: bar.standardAppearance, traits: traits)
        bar.scrollEdgeAppearance = applied(to: scrollEdge, traits: traits)
        if let compact = bar.compactAppearance {
            bar.compactAppearance = applied(to: compact, traits: traits)
        }
        if let compact = bar.compactScrollEdgeAppearance {
            bar.compactScrollEdgeAppearance = applied(to: compact, traits: traits)
        }
    }

    /// One screen: while `item` is on top, the bar uses these appearances.
    func apply(to item: UINavigationItem, in bar: UINavigationBar, traits: UITraitCollection) {
        let standard = item.standardAppearance ?? bar.standardAppearance
        let scrollEdge = item.scrollEdgeAppearance ?? bar.scrollEdgeAppearance ?? Self.transparent(standard)
        item.standardAppearance = applied(to: standard, traits: traits)
        item.scrollEdgeAppearance = applied(to: scrollEdge, traits: traits)
        if let compact = item.compactAppearance ?? bar.compactAppearance {
            item.compactAppearance = applied(to: compact, traits: traits)
        }
        if let compact = item.compactScrollEdgeAppearance ?? bar.compactScrollEdgeAppearance {
            item.compactScrollEdgeAppearance = applied(to: compact, traits: traits)
        }
    }

    /// What UIKit uses at the scroll edge when no appearance is set.
    private static func transparent(_ appearance: UINavigationBarAppearance) -> UINavigationBarAppearance {
        let copy = appearance.copy()
        copy.configureWithTransparentBackground()
        return copy
    }
}

/// A screen that wants its own back button look while it is on top.
/// `HostingController(rootView:backButton:)` adopts it; UIKit screens can too.
@MainActor
public protocol BackButtonStyling: UIViewController {
    /// `nil` = the navigator's style.
    var preferredBackButtonStyle: BackButtonStyle? { get }
}

enum BackIndicatorRenderer {
    /// A bitmap, because the bar re-tints and re-configures symbol images
    /// (palette colors are lost). Colors must already be resolved.
    @MainActor
    static func circle(symbol: String, foreground: UIColor, background: UIColor, border: UIColor?, diameter: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat.preferred()
        let size = CGSize(width: diameter, height: diameter)
        let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            let lineWidth = 1 / format.scale
            let circle = UIBezierPath(ovalIn: CGRect(origin: .zero, size: size).insetBy(dx: lineWidth, dy: lineWidth))
            background.setFill()
            circle.fill()
            if let border {
                border.setStroke()
                circle.lineWidth = lineWidth
                circle.stroke()
            }
            let configuration = UIImage.SymbolConfiguration(pointSize: diameter * 0.45, weight: .semibold)
            guard let glyph = UIImage(systemName: symbol, withConfiguration: configuration)?
                .withTintColor(foreground, renderingMode: .alwaysOriginal) else { return }
            // Chevrons look centered slightly left of the true center.
            let origin = CGPoint(x: (diameter - glyph.size.width) / 2 - diameter * 0.03, y: (diameter - glyph.size.height) / 2)
            glyph.draw(at: origin)
        }
        // UIKit ignores alignment insets here and caps the height, but it lines
        // the indicator up on the title baseline: put the circle's center on the
        // middle of the capitals (about 6 pt above the baseline).
        return image
            .withRenderingMode(.alwaysOriginal)
            .withBaselineOffset(fromBottom: diameter / 2 - 6)
            .imageFlippedForRightToLeftLayoutDirection()
    }
}
