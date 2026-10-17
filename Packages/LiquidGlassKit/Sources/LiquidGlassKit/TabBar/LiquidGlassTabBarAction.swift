//
//  LiquidGlassTabBarAction.swift
//  LiquidGlassKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import UIKit

/// A button in the tab bar that is not a tab: it runs your code instead of
/// switching screens (camera, compose, scan...).
///
///     tabs.actionButton = LiquidGlassTabBarAction(
///         image: UIImage(systemName: "camera.fill"),
///         title: "Camera"
///     ) { tabs in
///         tabs.present(CameraViewController(), animated: true)
///     }
///
/// Glass bar: sits in its own slot among the tabs, raised out of the bar
/// (`.raised`) or inside it (`.inline`); `.center` is the true center, tabs
/// split evenly around it. UIKit's bar cannot hold custom views, so with
/// `style: .system` the button floats above the bar. For the same look on
/// every version use `style: .glass`: on iOS 26 it is drawn with Apple's own
/// glass (`UIGlassEffect`).
///
/// The button sits in a glass **halo**, like the selection around a tab: it
/// swells and lights up under the finger, and its rim light and icon follow
/// the tilt of the phone. Tune it or turn it off:
///
///     action.halo = .clear                     // see-through ring
///     action.halo = .glass.padding(8)          // thicker ring
///     action.halo = nil                        // just the circle
///     action.followsMotion = false             // no tilt effects
public struct LiquidGlassTabBarAction {
    /// Where the slot goes among the tabs.
    public enum Placement: Sendable, Equatable {
        case leading
        case center
        case trailing
        /// Before the tab at this index.
        case index(Int)
    }

    public enum Style: Sendable, Equatable {
        /// Bigger, accent-filled circle that sticks out above the bar.
        case raised
        /// Accent-filled circle inside the bar, the size of a tab.
        case inline
    }

    public var image: UIImage?
    /// Read by VoiceOver and the large content viewer.
    public var title: String
    public var placement: Placement = .center
    public var style: Style = .raised
    /// Circle color. `nil` = the bar's `tintColor`.
    public var tint: UIColor?
    public var iconColor: UIColor = .white
    /// Raised circle size.
    public var diameter: CGFloat = 60
    /// How far the raised circle rises above the bar's center.
    public var lift: CGFloat = 18
    /// Glass ring around the button, like the selection around a tab. `nil` = none.
    public var halo: Halo? = .glass
    /// Rim light follows tilt and the button floats a little in its halo (parallax).
    /// Off with Reduce Motion.
    public var followsMotion = true
    /// Your own content instead of `image` (e.g. an avatar, an animated icon).
    public var customView: UIView?
    /// Runs on tap, with the tab bar controller (present, push, open a flow...).
    public var handler: @MainActor (LiquidGlassTabBarController) -> Void

    public init(
        image: UIImage?,
        title: String,
        placement: Placement = .center,
        style: Style = .raised,
        tint: UIColor? = nil,
        handler: @escaping @MainActor (LiquidGlassTabBarController) -> Void
    ) {
        self.image = image
        self.title = title
        self.placement = placement
        self.style = style
        self.tint = tint
        self.handler = handler
    }

    /// The glass ring around the action button.
    public struct Halo {
        /// Frosted ring, like the `.glass` selection.
        public static var glass: Halo { Halo() }
        /// See-through ring, for bars over media.
        public static var clear: Halo { Halo(isClear: true) }

        /// Ring thickness around the circle.
        public var padding: CGFloat = 6
        public var isClear = false
        /// Tints the ring. `nil` = plain glass.
        public var tint: UIColor?

        public init(padding: CGFloat = 6, isClear: Bool = false, tint: UIColor? = nil) {
            self.padding = padding
            self.isClear = isClear
            self.tint = tint
        }

        public func padding(_ value: CGFloat) -> Halo {
            var copy = self
            copy.padding = value
            return copy
        }

        public func tint(_ color: UIColor?) -> Halo {
            var copy = self
            copy.tint = color
            return copy
        }
    }

    /// Raised size with the halo (`diameter` is the circle alone).
    var raisedSize: CGFloat { diameter + 2 * (halo?.padding ?? 0) }

    /// Slot position among `tabCount` tabs.
    func slotIndex(tabCount: Int) -> Int {
        switch placement {
        case .leading: 0
        case .center: tabCount / 2
        case .trailing: tabCount
        case let .index(index): min(max(index, 0), tabCount)
        }
    }
}

/// The round glass button drawn for a `LiquidGlassTabBarAction`: an accent
/// circle in an optional glass halo, with press and tilt effects.
@MainActor
final class LiquidGlassActionButton: UIView {
    /// The ring around the circle (hidden when the action has no halo).
    let halo = LiquidGlassView()
    let glass = LiquidGlassView()
    private let icon = UIImageView()
    private weak var customView: UIView?
    private var haloPadding: CGFloat = 0
    private var parallax: UIMotionEffectGroup?
    private(set) var isPressed = false
    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        // No refraction: the lens would snapshot the button itself.
        halo.effects = [.specular, .motion]
        // Same frosted look as the selection pill on every version (Apple's
        // glass nearly disappears over light content at this size).
        halo.usesSystemGlass = false
        halo.isUserInteractionEnabled = false
        halo.isHidden = true
        addSubview(halo)
        glass.effects = [.specular, .motion]
        glass.tintOpacity = 0.92
        glass.isUserInteractionEnabled = false
        addSubview(glass)
        icon.contentMode = .center
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        glass.contentView.addSubview(icon)
        isAccessibilityElement = true
        accessibilityTraits = .button
        showsLargeContentViewer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported") // lint:allow – marked unavailable, can never be called
    }

    func configure(with action: LiquidGlassTabBarAction, tint: UIColor) {
        glass.glassTint = action.tint ?? tint
        icon.image = action.image
        icon.tintColor = action.iconColor
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: action.style == .raised ? 22 : 18, weight: .semibold
        )
        if let ring = action.halo {
            halo.isHidden = false
            halo.isClear = ring.isClear
            halo.glassTint = ring.tint
            haloPadding = max(ring.padding, 0)
        } else {
            halo.isHidden = true
            haloPadding = 0
        }
        let tilt: LiquidGlassView.Effects = action.followsMotion ? [.specular, .motion] : [.specular]
        halo.effects = tilt
        glass.effects = tilt
        setParallax(action.followsMotion)
        if customView !== action.customView {
            customView?.removeFromSuperview()
            if let custom = action.customView { glass.contentView.addSubview(custom) }
            customView = action.customView
        }
        icon.isHidden = action.customView != nil
        accessibilityLabel = action.title
        largeContentTitle = action.title
        largeContentImage = action.image
        setNeedsLayout()
    }

    /// The circle floats a little inside its halo as the phone tilts (UIKit
    /// turns motion effects off with Reduce Motion).
    private func setParallax(_ isOn: Bool) {
        guard isOn != (parallax != nil) else { return }
        if let parallax {
            glass.removeMotionEffect(parallax)
            self.parallax = nil
            return
        }
        let range: CGFloat = 3
        let x = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        x.minimumRelativeValue = -range
        x.maximumRelativeValue = range
        let y = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        y.minimumRelativeValue = -range
        y.maximumRelativeValue = range
        let group = UIMotionEffectGroup()
        group.motionEffects = [x, y]
        glass.addMotionEffect(group)
        parallax = group
    }

    var followsMotion: Bool { parallax != nil }

    /// Pressed: the halo swells and lights up under the finger, the circle
    /// sinks a little; released: both spring back. `point` in this view.
    func setPressed(_ pressed: Bool, at point: CGPoint? = nil) {
        let target = halo.isHidden ? glass : halo
        target.setPressed(pressed, at: point.map { convert($0, to: target) })
        if !halo.isHidden { glass.setPressed(pressed, at: point.map { convert($0, to: glass) }) }
        guard pressed != isPressed else { return }
        isPressed = pressed
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        UIView.animate(
            withDuration: pressed ? 0.3 : 0.55, delay: 0,
            usingSpringWithDamping: pressed ? 0.7 : 0.45, initialSpringVelocity: 0.8,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            self.icon.transform = pressed ? CGAffineTransform(scaleX: 0.86, y: 0.86) : .identity
            self.customView?.transform = self.icon.transform
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 1, bounds.height > 1 else { return }
        halo.bounds = CGRect(origin: .zero, size: bounds.size)
        halo.center = CGPoint(x: bounds.midX, y: bounds.midY)
        // A thin bar (inline style) keeps at least most of the room for the circle.
        let padding = min(haloPadding, bounds.width * 0.15)
        let inner = bounds.insetBy(dx: padding, dy: padding)
        glass.bounds = CGRect(origin: .zero, size: inner.size)
        glass.center = CGPoint(x: bounds.midX, y: bounds.midY)
        // The glass lays out its content later: size from the circle's own size.
        icon.bounds = CGRect(origin: .zero, size: inner.size)
        icon.center = CGPoint(x: inner.width / 2, y: inner.height / 2)
        customView?.bounds = CGRect(origin: .zero, size: inner.size)
        customView?.center = icon.center
    }

    override func accessibilityActivate() -> Bool {
        onTap?()
        return true
    }
}
