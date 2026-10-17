//
//  LiquidGlassView.swift
//  LiquidGlassKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import UIKit

/// iOS 26 "Liquid Glass" for iOS 17+, built from public UIKit only.
///
///     let glass = LiquidGlassView()
///     glass.backdrop = scrollContainer      // what is behind it: enables lensing + adaptive color
///     glass.contentView.addSubview(icon)
///
/// Effects (all on by default, see `Effects`):
/// - **Refraction**: the content behind is magnified along the rim, like light
///   bending through the edge of a lens (live snapshot of `backdrop`).
/// - **Specular**: a bright rim light plus a softer one on the opposite side.
/// - **Motion**: those highlights move when the phone tilts (`LiquidGlassMotion`).
/// - **Adaptive**: light glass over light content, dark glass over dark content
///   (`adaptiveStyle`), like iOS 26.
/// - **Interaction**: `setPressed(_:at:)` swells the glass and lights it where it is touched.
///
/// Respects Reduce Transparency (solid, no lens), Reduce Motion (no tilt, no
/// swell), Increase Contrast (stronger rim), Low Power Mode and heat (lens updated less often).
@MainActor
open class LiquidGlassView: UIView {
    public struct Effects: OptionSet, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }

        public static let refraction = Effects(rawValue: 1 << 0)
        public static let specular = Effects(rawValue: 1 << 1)
        public static let motion = Effects(rawValue: 1 << 2)
        public static let adaptive = Effects(rawValue: 1 << 3)
        public static let all: Effects = [.refraction, .specular, .motion, .adaptive]
    }

    /// Put your content here (clipped to the glass).
    public let contentView = UIView()

    /// Which effects run. Default: all.
    public var effects: Effects = .all {
        didSet { effectsChanged() }
    }

    /// `nil` = capsule (height / 2).
    public var cornerRadius: CGFloat? {
        didSet { setNeedsLayout() }
    }

    /// Tinted glass (e.g. a brand-colored button). `nil` = untinted.
    public var glassTint: UIColor? {
        didSet { updateAppearance() }
    }

    /// How strongly `glassTint` colors the glass (0...1). Higher = more solid.
    public var tintOpacity: CGFloat = 0.55 {
        didSet { updateAppearance() }
    }

    /// Clear glass (no frost), like iOS 26's selection lens: shows what is
    /// under it, only rim light and a faint tint.
    public var isClear = false {
        didSet { updateAppearance() }
    }

    /// On iOS 26, draw with Apple's own `UIGlassEffect` instead of the kit's
    /// layers (default: yes when the system design is Liquid Glass). Your code
    /// does not change; iOS 17–18 always use the kit's drawing.
    public var usesSystemGlass = LiquidGlass.isSystemDesign {
        didSet { effectsChanged() }
    }

    /// `true` when this view is drawn by the system (iOS 26 `UIGlassEffect`).
    public var isSystemGlass: Bool {
        guard usesSystemGlass, #available(iOS 26, *) else { return false }
        return true
    }

    /// The view behind the glass (not an ancestor of it). Needed for
    /// refraction and adaptive color; without it the glass is frosted only.
    public weak var backdrop: UIView? {
        didSet { setNeedsBackdropUpdate() }
    }

    /// Shadow strength. `nil` = automatic (stronger in dark mode).
    public var shadowOpacity: Float? {
        didSet { updateAppearance() }
    }

    /// How much the rim magnifies what is behind (1 = no bending).
    public var lensMagnification: CGFloat = 1.16 {
        didSet { setNeedsLayout() }
    }

    /// Style forced by the content behind (`.adaptive`): `.light` over light
    /// content in dark mode, `.dark` over dark content in light mode.
    /// `.unspecified` = the glass follows the system.
    public private(set) var adaptiveStyle: UIUserInterfaceStyle = .unspecified
    /// Called when `adaptiveStyle` flips (e.g. to recolor custom content).
    public var onAdaptiveStyleChange: ((UIUserInterfaceStyle) -> Void)?

    // Layers, back to front.
    private let clip = UIView()
    private let material = UIVisualEffectView()
    private let lensHost = UIView()
    private let lensMask = UIImageView()
    private(set) var lensSnapshot: UIView?
    private let tintView = UIView()
    private let sheen = CAGradientLayer()
    private let glow = CAGradientLayer()
    private let rim = CAShapeLayer()
    private let specular = CAGradientLayer()
    private let specularMask = CAShapeLayer()
    private let bevel = CAGradientLayer()
    private let bevelMask = CAShapeLayer()

    private var light = LiquidGlassMotion.shared.light
    private var motionToken: LiquidGlassMotion.Token?
    private var ticker: CADisplayLink?
    private var idleTimer: Timer?
    private var activeUntil: CFTimeInterval = 0
    /// `true` between `setPressed(true)` and `setPressed(false)`.
    public private(set) var isPressed = false

    private static let instances = NSHashTable<LiquidGlassView>.weakObjects()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        Self.instances.add(self)

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 8)

        clip.clipsToBounds = true
        clip.layer.cornerCurve = .continuous
        clip.isUserInteractionEnabled = false
        addSubview(clip)
        clip.addSubview(material)

        lensHost.clipsToBounds = true
        lensHost.isUserInteractionEnabled = false
        // Refraction is a hint at the rim, not a second copy of the content.
        lensHost.alpha = 0.6
        lensHost.mask = lensMask
        clip.addSubview(lensHost)

        tintView.isUserInteractionEnabled = false
        clip.addSubview(tintView)

        sheen.locations = [0, 0.5]
        clip.layer.addSublayer(sheen)

        glow.type = .radial
        glow.colors = [UIColor.white.withAlphaComponent(0.32).cgColor, UIColor.white.withAlphaComponent(0).cgColor]
        glow.opacity = 0
        clip.layer.addSublayer(glow)

        addSubview(contentView)
        contentView.clipsToBounds = true
        contentView.layer.cornerCurve = .continuous

        rim.fillColor = nil
        rim.lineWidth = 1
        layer.addSublayer(rim)

        bevel.type = .conic
        bevel.mask = bevelMask
        bevelMask.fillColor = nil
        bevelMask.lineWidth = 6
        bevelMask.strokeColor = UIColor.white.cgColor
        layer.addSublayer(bevel)

        specular.type = .conic
        specular.mask = specularMask
        specularMask.fillColor = nil
        specularMask.lineWidth = 1.5
        specularMask.strokeColor = UIColor.white.cgColor
        layer.addSublayer(specular)

        registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self]) { (glass: LiquidGlassView, _) in
            glass.updateAppearance()
        }
        let center = NotificationCenter.default
        for name in [
            UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            UIAccessibility.reduceMotionStatusDidChangeNotification,
            Notification.Name.NSProcessInfoPowerStateDidChange,
        ] {
            center.addObserver(self, selector: #selector(environmentChanged), name: name, object: nil)
        }
        effectsChanged()
    }

    isolated deinit {
        ticker?.invalidate()
        idleTimer?.invalidate()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported") // lint:allow – marked unavailable, can never be called
    }

    // MARK: - Public API

    /// Swells the glass and lights it under the finger (`point` in this view).
    public func setPressed(_ pressed: Bool, at point: CGPoint? = nil) {
        if let point { movePressPoint(to: point) }
        guard pressed != isPressed else { return }
        isPressed = pressed
        let swell = !UIAccessibility.isReduceMotionEnabled
        UIView.animate(
            withDuration: pressed ? 0.35 : 0.5, delay: 0,
            usingSpringWithDamping: pressed ? 0.6 : 0.55, initialSpringVelocity: 0.6,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            self.transform = pressed && swell ? CGAffineTransform(scaleX: 1.035, y: 1.06) : .identity
        }
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = glow.presentation()?.opacity ?? glow.opacity
        fade.duration = pressed ? 0.15 : 0.45
        glow.opacity = pressed ? 1 : 0
        glow.add(fade, forKey: "fade")
    }

    /// Moves the touch light (`point` in this view).
    public func movePressPoint(to point: CGPoint) {
        let size: CGFloat = max(bounds.height * 2.2, 120)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        glow.frame = CGRect(x: point.x - size / 2, y: point.y - size / 2, width: size, height: size)
        glow.startPoint = CGPoint(x: 0.5, y: 0.5)
        glow.endPoint = CGPoint(x: 1, y: 1)
        CATransaction.commit()
    }

    /// The content behind is changing (scroll, push...): keep the lens and
    /// the adaptive color live for `duration` seconds.
    public func setNeedsBackdropUpdate(duration: TimeInterval = 0.35) {
        guard window != nil, needsBackdrop else { return }
        activeUntil = max(activeUntil, CACurrentMediaTime() + duration)
        guard ticker == nil else { return }
        let link = CADisplayLink(target: GlassTicker(self), selector: #selector(GlassTicker.tick))
        // Lens refresh does not need ProMotion rates; 60 is plenty (30 in Low Power Mode).
        let maxRate: Float = isEnergySaving ? 30 : 60
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: maxRate, preferred: maxRate)
        link.add(to: .main, forMode: .common)
        ticker = link
    }

    /// Every glass on screen: the whole screen is about to change (navigation transition).
    public static func backdropWillChange(duration: TimeInterval = 0.5) {
        for glass in instances.allObjects {
            glass.setNeedsBackdropUpdate(duration: duration)
        }
    }

    // MARK: - Layout

    override open func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 1, bounds.height > 1 else { return }
        let radius = min(cornerRadius ?? bounds.height / 2, bounds.height / 2, bounds.width / 2)
        clip.frame = bounds
        clip.layer.cornerRadius = radius
        contentView.frame = bounds
        contentView.layer.cornerRadius = radius
        material.frame = clip.bounds
        tintView.frame = clip.bounds
        lensHost.frame = clip.bounds
        lensMask.image = GlassShapes.rimFalloff(cornerRadius: radius, depth: min(radius, 12))
        lensMask.frame = lensHost.bounds
        layoutLensSnapshot()

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        sheen.frame = clip.bounds
        let outline = UIBezierPath(roundedRect: bounds, cornerRadius: radius).cgPath
        layer.shadowPath = outline
        rim.path = UIBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), cornerRadius: max(radius - 0.5, 0)).cgPath
        for (gradient, mask, inset) in [(specular, specularMask, CGFloat(0.75)), (bevel, bevelMask, CGFloat(3))] {
            gradient.frame = bounds
            mask.frame = bounds
            mask.path = UIBezierPath(roundedRect: bounds.insetBy(dx: inset, dy: inset), cornerRadius: max(radius - inset, 0)).cgPath
        }
        CATransaction.commit()
        updateSpecular()
    }

    override open func didMoveToWindow() {
        super.didMoveToWindow()
        effectsChanged()
    }

    // MARK: - Appearance

    @objc private func environmentChanged() {
        effectsChanged()
    }

    private var reduceTransparency: Bool { UIAccessibility.isReduceTransparencyEnabled }
    private var isEnergySaving: Bool {
        ProcessInfo.processInfo.isLowPowerModeEnabled || ProcessInfo.processInfo.thermalState.rawValue >= ProcessInfo.ThermalState.serious.rawValue
    }
    private var needsBackdrop: Bool {
        backdrop != nil && !reduceTransparency && !isSystemGlass && !effects.isDisjoint(with: [.refraction, .adaptive])
    }

    private func effectsChanged() {
        if effects.contains(.motion), effects.contains(.specular), window != nil, !isSystemGlass {
            if motionToken == nil {
                motionToken = LiquidGlassMotion.shared.observe { [weak self] light in
                    self?.light = light
                    self?.updateSpecular()
                }
            }
        } else {
            motionToken = nil
        }
        if !effects.contains(.adaptive) || reduceTransparency {
            setAdaptiveStyle(.unspecified)
        }
        if !effects.contains(.refraction) || reduceTransparency {
            lensSnapshot?.removeFromSuperview()
            lensSnapshot = nil
        }
        idleTimer?.invalidate()
        idleTimer = nil
        if window != nil, needsBackdrop {
            // Catches changes nobody reports (images loading, auto-playing content).
            idleTimer = Timer.scheduledTimer(withTimeInterval: isEnergySaving ? 2 : 1, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.refreshBackdrop(sampleLuminance: true) }
            }
            // After the first frame: snapshots of views not yet rendered are empty.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.refreshBackdrop(sampleLuminance: true)
            }
        } else {
            stopTicker()
        }
        updateAppearance()
    }

    func updateAppearance() {
        if isSystemGlass, !reduceTransparency, #available(iOS 26, *) {
            applySystemGlass()
            return
        }
        [tintView, lensHost].forEach { $0.isHidden = false }
        rim.isHidden = false
        let dark = traitCollection.userInterfaceStyle == .dark
        let highContrast = traitCollection.accessibilityContrast == .high
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        if reduceTransparency {
            material.effect = nil
            material.backgroundColor = .secondarySystemBackground
            tintView.backgroundColor = glassTint
            sheen.isHidden = true
            lensHost.isHidden = true
        } else if isClear {
            material.effect = nil
            material.backgroundColor = nil
            tintView.backgroundColor = glassTint?.withAlphaComponent(0.2) ?? UIColor(white: 1, alpha: dark ? 0.06 : 0.14)
            sheen.isHidden = false
            sheen.colors = [
                UIColor.white.withAlphaComponent(dark ? 0.12 : 0.4).cgColor,
                UIColor.white.withAlphaComponent(0).cgColor,
            ]
            lensHost.isHidden = !effects.contains(.refraction)
        } else {
            material.effect = UIBlurEffect(style: dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight)
            material.backgroundColor = nil
            let base = dark ? UIColor(white: 0.08, alpha: 0.3) : UIColor(white: 1, alpha: 0.55)
            tintView.backgroundColor = glassTint?.withAlphaComponent(tintOpacity) ?? base
            sheen.isHidden = false
            sheen.colors = [
                UIColor.white.withAlphaComponent(dark ? 0.1 : 0.32).cgColor,
                UIColor.white.withAlphaComponent(0).cgColor,
            ]
            lensHost.isHidden = !effects.contains(.refraction)
        }
        rim.strokeColor = UIColor.white.withAlphaComponent(highContrast ? 0.95 : (dark ? 0.16 : 0.6)).cgColor
        if highContrast {
            rim.lineWidth = 1.5
        }
        layer.shadowOpacity = shadowOpacity ?? (dark ? 0.32 : 0.12)
        layer.shadowRadius = dark ? 22 : 18
        specular.isHidden = !effects.contains(.specular) || reduceTransparency
        bevel.isHidden = specular.isHidden
        let peak = dark ? 0.55 : 0.95
        specular.colors = Self.highlightColors(peak: peak)
        specular.locations = Self.highlightLocations
        bevel.colors = Self.highlightColors(peak: dark ? 0.12 : 0.28)
        bevel.locations = Self.highlightLocations
        CATransaction.commit()
    }

    /// iOS 26: Apple's glass does refraction, highlights, adaptivity and
    /// interaction itself; the kit's layers step aside.
    @available(iOS 26, *)
    private func applySystemGlass() {
        let glass = UIGlassEffect(style: isClear ? .clear : .regular)
        glass.tintColor = glassTint
        glass.isInteractive = true
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        material.effect = glass
        material.backgroundColor = nil
        tintView.isHidden = true
        lensHost.isHidden = true
        sheen.isHidden = true
        rim.isHidden = true
        specular.isHidden = true
        bevel.isHidden = true
        layer.shadowOpacity = shadowOpacity ?? 0
        CATransaction.commit()
    }

    /// Bright spot facing the light, softer one on the far side.
    private static func highlightColors(peak: Double) -> [CGColor] {
        let spot = UIColor.white.withAlphaComponent(peak).cgColor
        let soft = UIColor.white.withAlphaComponent(peak * 0.5).cgColor
        let clear = UIColor.white.withAlphaComponent(0).cgColor
        return [spot, clear, clear, soft, clear, clear, spot]
    }

    private static let highlightLocations: [NSNumber] = [0, 0.14, 0.36, 0.5, 0.64, 0.86, 1]

    /// Points the highlights at the light (conic gradient: angle 0 = `endPoint`).
    func updateSpecular() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let center = CGPoint(x: 0.5, y: 0.5)
        let aspect = bounds.height > 0 ? bounds.width / bounds.height : 1
        // Unit space is stretched on wide shapes: squash x so the angle looks right.
        let end = CGPoint(x: 0.5 + light.dx * 0.5 / max(aspect, 1), y: 0.5 + light.dy * 0.5)
        for gradient in [specular, bevel] {
            gradient.startPoint = center
            gradient.endPoint = end
        }
        sheen.startPoint = CGPoint(x: 0.5 + light.dx * 0.5, y: 0.5 + light.dy * 0.5)
        sheen.endPoint = CGPoint(x: 0.5 - light.dx * 0.5, y: 0.5 - light.dy * 0.5)
        CATransaction.commit()
    }

    // MARK: - Backdrop (refraction + adaptive color)

    /// Every frame while the backdrop moves: lens only (~1 ms). The color
    /// check (a small render, a few ms) waits until the movement stops.
    fileprivate func tick() {
        let finished = CACurrentMediaTime() > activeUntil
        refreshBackdrop(sampleLuminance: finished)
        if finished { stopTicker() }
    }

    /// `true` while the lens follows the backdrop every frame.
    var isBackdropLive: Bool { ticker != nil }
    var hasMotion: Bool { motionToken != nil }
    var specularEndPoint: CGPoint { specular.endPoint }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    func refreshBackdrop(sampleLuminance: Bool) {
        guard let backdrop, let window, backdrop.window === window, !reduceTransparency else { return }
        let rect = convert(bounds, to: backdrop)
        guard rect.intersects(backdrop.bounds) else { return }
        if effects.contains(.refraction) {
            refreshLens(from: backdrop, rect: rect)
        }
        if sampleLuminance, effects.contains(.adaptive) {
            if let luminance = Self.averageLuminance(of: backdrop, in: rect) {
                apply(luminance: luminance)
            }
        }
    }

    private func refreshLens(from backdrop: UIView, rect: CGRect) {
        // A render-server snapshot: cheap, no pixels copied to the CPU.
        guard let snapshot = backdrop.resizableSnapshotView(
            from: rect, afterScreenUpdates: false, withCapInsets: .zero
        ) else { return }
        snapshot.isUserInteractionEnabled = false
        lensSnapshot?.removeFromSuperview()
        lensHost.addSubview(snapshot)
        lensSnapshot = snapshot
        layoutLensSnapshot()
    }

    private func layoutLensSnapshot() {
        guard let lensSnapshot else { return }
        lensSnapshot.transform = .identity
        lensSnapshot.frame = lensHost.bounds
        // Magnify about the center: the rim shows what is just inside, enlarged.
        lensSnapshot.transform = CGAffineTransform(scaleX: lensMagnification, y: lensMagnification * 1.08)
    }

    /// Average luminance (0 dark ... 1 light) of `rect` in `view`, from a tiny render.
    static func averageLuminance(of view: UIView, in rect: CGRect) -> CGFloat? {
        let width = 8, height = 2
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn: Bool = pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.translateBy(x: 0, y: CGFloat(height))
            context.scaleBy(x: CGFloat(width) / rect.width, y: -CGFloat(height) / rect.height)
            context.translateBy(x: -rect.minX, y: -rect.minY)
            UIGraphicsPushContext(context)
            defer { UIGraphicsPopContext() }
            return view.drawHierarchy(in: view.bounds, afterScreenUpdates: false)
        }
        guard drawn else { return nil }
        var total: CGFloat = 0
        for index in stride(from: 0, to: pixels.count, by: 4) {
            let r = CGFloat(pixels[index]), g = CGFloat(pixels[index + 1]), b = CGFloat(pixels[index + 2])
            total += (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255
        }
        return total / CGFloat(width * height)
    }

    /// Flips light/dark with hysteresis, so content near the middle does not flicker.
    func apply(luminance: CGFloat) {
        let system = window?.traitCollection.userInterfaceStyle ?? .light
        let current = adaptiveStyle == .unspecified ? system : adaptiveStyle
        var next = current
        if current == .dark, luminance > 0.62 {
            next = .light
        } else if current != .dark, luminance < 0.36 {
            next = .dark
        }
        // Same as the system: stop overriding, follow it again.
        setAdaptiveStyle(next == system ? .unspecified : next)
    }

    private func setAdaptiveStyle(_ style: UIUserInterfaceStyle) {
        guard style != adaptiveStyle else { return }
        adaptiveStyle = style
        let change = { self.overrideUserInterfaceStyle = style }
        if window != nil, !UIAccessibility.isReduceMotionEnabled {
            UIView.transition(with: self, duration: 0.3, options: [.transitionCrossDissolve, .allowUserInteraction], animations: change)
        } else {
            change()
        }
        onAdaptiveStyleChange?(style)
    }
}

/// Breaks the CADisplayLink -> target retain cycle.
@MainActor
private final class GlassTicker: NSObject {
    weak var glass: LiquidGlassView?

    init(_ glass: LiquidGlassView) {
        self.glass = glass
    }

    @objc func tick(_ link: CADisplayLink) {
        guard let glass else {
            link.invalidate()
            return
        }
        glass.tick()
    }
}
