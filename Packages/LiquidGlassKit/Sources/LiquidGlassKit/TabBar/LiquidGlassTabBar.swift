//
//  LiquidGlassTabBar.swift
//  LiquidGlassKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import UIKit

/// The floating bar drawn by `LiquidGlassTabBarController`.
/// Configure it through `LiquidGlassTabBarController.appearance`.
///
/// Like iOS 26:
/// - glass with refraction, rim light that follows tilt, adaptive light/dark (`LiquidGlassView`);
/// - touch: the bar swells and lights up under the finger;
/// - a glass **droplet** lifts from the selection, follows the finger (press
///   and slide across tabs), magnifies the icons under it, stretches with
///   speed, then lands on the tab with a spring;
/// - selection haptics while sliding;
/// - minimized state: a small glass circle with the current tab's icon.
@MainActor
final class LiquidGlassTabBar: UIView {
    /// A tab was chosen (tap, slide, VoiceOver, large content viewer).
    var onSelect: ((Int) -> Void)?
    /// Tap on the minimized bar.
    var onExpandRequest: (() -> Void)?
    /// Tap on the action button (not a tab).
    var onAction: (() -> Void)?

    private(set) var appearance = LiquidGlassTabBarAppearance.default
    private(set) var buttons: [LiquidGlassTabButton] = []
    private(set) var selectedIndex = 0
    private(set) var isMinimized = false

    let glass = LiquidGlassView()
    let indicator = SelectionIndicatorView()
    let droplet = LiquidGlassDroplet()
    /// Holds the tabs (and the action slot), laid out by `layoutSlots`.
    private let stack = UIView()
    /// Tabs and the action slot, in order.
    private var slots: [UIView] = []
    private let minimizedIcon = UIImageView()
    private let haptics = UISelectionFeedbackGenerator()
    private var items: [UITabBarItem] = []
    private var itemObservations: [NSKeyValueObservation] = []

    private(set) var action: LiquidGlassTabBarAction?
    let actionButton = LiquidGlassActionButton()
    /// Empty slot among the tabs where the action button sits.
    private let actionSlot = UIView()
    private var isTrackingAction = false
    private let impact = UIImpactFeedbackGenerator(style: .medium)

    private(set) var isDragging = false
    private var dragIndex = 0
    private var lastDrag: (x: CGFloat, time: CFTimeInterval) = (0, 0)

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(glass)
        glass.contentView.addSubview(indicator)

        glass.contentView.addSubview(stack)

        minimizedIcon.contentMode = .center
        minimizedIcon.alpha = 0
        glass.contentView.addSubview(minimizedIcon)

        droplet.alpha = 0
        droplet.isUserInteractionEnabled = false
        addSubview(droplet)

        actionSlot.isUserInteractionEnabled = false
        actionButton.isHidden = true
        actionButton.onTap = { [weak self] in self?.onAction?() }
        addSubview(actionButton)

        let press = UILongPressGestureRecognizer(target: self, action: #selector(handlePress(_:)))
        press.minimumPressDuration = 0
        press.allowableMovement = .greatestFiniteMagnitude
        press.delegate = self
        addGestureRecognizer(press)

        // Like the system tab bar: one accessibility container with tabs,
        // and the large content viewer instead of growing with Dynamic Type.
        accessibilityTraits = .tabBar
        addInteraction(UILargeContentViewerInteraction(delegate: self))
        apply(appearance)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported") // lint:allow – marked unavailable, can never be called
    }

    // MARK: - Configuration

    func apply(_ appearance: LiquidGlassTabBarAppearance) {
        self.appearance = appearance
        glass.effects = appearance.glass.effects
        glass.glassTint = appearance.glass.tint
        glass.isClear = appearance.glass.isClear
        glass.lensMagnification = appearance.glass.refraction
        glass.cornerRadius = appearance.bar.cornerRadius
        glass.shadowOpacity = appearance.glass.shadowOpacity
        minimizedIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: appearance.item.iconPointSize + 1, weight: appearance.item.iconWeight
        )
        buttons.forEach { $0.apply(appearance, tint: tintColor) }
        applySelectionColors()
        setNeedsLayout()
        layoutIfNeeded()
        moveIndicator(animated: false)
    }

    private func applySelectionColors() {
        indicator.configure(
            style: appearance.selection.style,
            color: appearance.indicatorColor(tint: tintColor),
            cornerRadius: appearance.selection.cornerRadius
        )
        buttons.forEach { $0.apply(appearance, tint: tintColor) }
        if let action { actionButton.configure(with: action, tint: tintColor) }
        updateMinimizedIcon()
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        applySelectionColors()
    }

    // MARK: - Items

    /// Rebuilds the tabs. Title, image, selected image and badge changes show up live.
    func setItems(_ items: [UITabBarItem]) {
        self.items = items
        buttons.forEach { $0.removeFromSuperview() }
        itemObservations = []
        buttons = items.enumerated().map { index, item in
            let button = LiquidGlassTabButton()
            button.apply(appearance, tint: tintColor)
            button.configure(with: item)
            // Touches go through the bar's gesture; this action serves VoiceOver and tests.
            button.isUserInteractionEnabled = false
            button.onActivate = { [weak self] in self?.onSelect?(index) }
            button.addAction(UIAction { [weak self] _ in self?.onSelect?(index) }, for: .touchUpInside)
            // KVO may call from any thread. Capture only the (main-actor, Sendable)
            // views; the button re-reads its own item on the main actor.
            let refresh: @Sendable () -> Void = { [weak self, weak button] in
                Task { @MainActor in
                    button?.reloadItem()
                    self?.updateMinimizedIcon()
                }
            }
            itemObservations += [
                item.observe(\.title) { _, _ in refresh() },
                item.observe(\.image) { _, _ in refresh() },
                item.observe(\.selectedImage) { _, _ in refresh() },
                item.observe(\.badgeValue) { _, _ in refresh() },
            ]
            return button
        }
        selectedIndex = min(selectedIndex, max(buttons.count - 1, 0))
        arrangeSlots()
        updateSelectedState()
        updateMinimizedIcon()
    }

    /// Adds, changes or removes the action button (`nil`).
    func setAction(_ action: LiquidGlassTabBarAction?) {
        self.action = action
        actionButton.isHidden = action == nil || isMinimized
        if let action { actionButton.configure(with: action, tint: tintColor) }
        arrangeSlots()
    }

    /// Tabs in order, with the action slot inserted where it belongs.
    private func arrangeSlots() {
        slots.forEach { $0.removeFromSuperview() }
        var views: [UIView] = buttons
        if let action {
            views.insert(actionSlot, at: action.slotIndex(tabCount: buttons.count))
        }
        slots = views
        views.forEach(stack.addSubview)
        updateAccessibilityOrder()
        setNeedsLayout()
        layoutIfNeeded()
        moveIndicator(animated: false)
    }

    private var slotCount: Int { buttons.count + (action == nil ? 0 : 1) }

    private func updateAccessibilityOrder() {
        if isMinimized {
            accessibilityElements = [minimizedIcon]
        } else if action != nil {
            accessibilityElements = slots.map { $0 === actionSlot ? actionButton : $0 }
        } else {
            accessibilityElements = nil
        }
    }

    /// Moves the selection with the appearance's animation.
    func select(_ index: Int, animated: Bool) {
        guard buttons.indices.contains(index) else { return }
        let changed = index != selectedIndex
        selectedIndex = index
        updateSelectedState()
        // While the droplet is out, it does the moving; the indicator waits under it.
        guard !isDragging else { return }
        moveIndicator(animated: animated && changed)
        if animated, changed, appearance.selection.bouncesIcon, !UIAccessibility.isReduceMotionEnabled {
            buttons[index].bounce()
        }
        updateMinimizedIcon()
    }

    /// Width that fits the tabs (not wider than `maxWidth`).
    func preferredWidth(maxWidth: CGFloat) -> CGFloat {
        if isMinimized { return appearance.bar.minimizedSize }
        if appearance.bar.fillsWidth { return maxWidth }
        return min(maxWidth, CGFloat(slotCount) * appearance.bar.itemWidth + appearance.bar.contentInset * 2)
    }

    var preferredHeight: CGFloat {
        isMinimized ? appearance.bar.minimizedSize : appearance.bar.height
    }

    /// Small circle with the current tab's icon (iOS 26 "minimize on scroll").
    /// The owner animates the frame; this switches the content.
    func setMinimized(_ minimized: Bool) {
        guard minimized != isMinimized else { return }
        isMinimized = minimized
        if minimized { cancelDroplet() }
        stack.alpha = minimized ? 0 : 1
        indicator.alpha = minimized ? 0 : 1
        minimizedIcon.alpha = minimized ? 1 : 0
        actionButton.alpha = minimized ? 0 : 1
        minimizedIcon.isAccessibilityElement = minimized
        minimizedIcon.accessibilityTraits = .button
        updateAccessibilityOrder()
        updateMinimizedIcon()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        // UIKit may lay out before the bar has a size.
        guard bounds.width > 1, bounds.height > 1 else { return }
        glass.bounds = CGRect(origin: .zero, size: bounds.size)
        glass.center = CGPoint(x: bounds.midX, y: bounds.midY)
        let inset = appearance.bar.contentInset
        // Minimized: keep the tabs at full width so they fade instead of squeezing.
        let fullWidth = CGFloat(slotCount) * appearance.bar.itemWidth
        let width = isMinimized ? max(fullWidth, bounds.width - inset * 2) : bounds.width - inset * 2
        let height = (isMinimized ? appearance.bar.height : bounds.height) - inset * 2
        stack.frame = CGRect(x: inset, y: inset, width: width, height: height)
        minimizedIcon.frame = CGRect(origin: .zero, size: bounds.size)
        layoutSlots()
        if !isDragging, indicator.layer.animationKeys()?.isEmpty ?? true {
            indicator.frame = indicatorFrame(for: selectedIndex)
        }
        layoutActionButton()
    }

    /// Equal widths; a `.center` action sits at the true center, with the tabs
    /// split evenly on both sides (so 3 tabs + camera still looks balanced).
    private func layoutSlots() {
        let width = stack.bounds.width
        let height = stack.bounds.height
        guard !slots.isEmpty, width > 0 else { return }
        var widths = Array(repeating: width / CGFloat(slots.count), count: slots.count)
        if let action, action.placement == .center, let slotIndex = slots.firstIndex(where: { $0 === actionSlot }),
           slotIndex > 0, slotIndex < slots.count - 1 {
            let slotWidth = width / CGFloat(slots.count)
            let side = (width - slotWidth) / 2
            let left = slotIndex
            let right = slots.count - slotIndex - 1
            for index in slots.indices {
                if index < slotIndex {
                    widths[index] = side / CGFloat(max(left, 1))
                } else if index > slotIndex {
                    widths[index] = side / CGFloat(max(right, 1))
                } else {
                    widths[index] = slotWidth
                }
            }
        }
        var x: CGFloat = 0
        for (view, slotWidth) in zip(slots, widths) {
            view.frame = CGRect(x: x, y: 0, width: slotWidth, height: height)
            x += slotWidth
        }
    }

    private func layoutActionButton() {
        guard let action, !isMinimized else { return }
        let slot = stack.convert(actionSlot.frame, to: self)
        let size: CGFloat
        let centerY: CGFloat
        switch action.style {
        case .raised:
            size = action.raisedSize
            centerY = bounds.midY - action.lift
        case .inline:
            size = slot.height - 4
            centerY = slot.midY
        }
        actionButton.bounds = CGRect(x: 0, y: 0, width: size, height: size)
        actionButton.center = CGPoint(x: slot.midX, y: centerY)
    }

    /// The raised action button sticks out of the bar: it still gets touches.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if super.point(inside: point, with: event) { return true }
        return action != nil && !isMinimized && actionButton.frame.insetBy(dx: -6, dy: -6).contains(point)
    }

    /// The tab's frame in the glass content.
    private func tabFrame(for index: Int) -> CGRect {
        guard buttons.indices.contains(index) else { return .zero }
        return stack.convert(buttons[index].frame, to: glass.contentView)
    }

    private func indicatorFrame(for index: Int) -> CGRect {
        SelectionIndicatorView.frame(for: appearance.selection.style, in: tabFrame(for: index), inset: appearance.selection.inset)
    }

    private func updateSelectedState() {
        for (index, button) in buttons.enumerated() {
            button.isSelected = index == selectedIndex
        }
    }

    private func moveIndicator(animated: Bool) {
        let target = indicatorFrame(for: selectedIndex)
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        switch animated && !reduceMotion && window != nil ? appearance.selection.animation : .none {
        case .none:
            indicator.frame = target
        case .spring:
            UIView.animate(
                withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.3,
                options: [.beginFromCurrentState, .allowUserInteraction]
            ) { self.indicator.frame = target }
        case .liquid:
            // The drop first stretches over both tabs, then springs into place.
            let stretched = indicator.frame.union(target)
            UIView.animate(withDuration: 0.14, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
                self.indicator.frame = stretched
            } completion: { _ in
                UIView.animate(
                    withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.68, initialSpringVelocity: 0.4,
                    options: [.beginFromCurrentState, .allowUserInteraction]
                ) { self.indicator.frame = self.indicatorFrame(for: self.selectedIndex) }
            }
        }
    }

    private func updateMinimizedIcon() {
        guard buttons.indices.contains(selectedIndex) else { return }
        let button = buttons[selectedIndex]
        minimizedIcon.image = button.currentImage
        minimizedIcon.tintColor = appearance.selection.style == .solid
            ? appearance.indicatorColor(tint: tintColor)
            : appearance.selectedItemColor(tint: tintColor)
        minimizedIcon.accessibilityLabel = button.accessibilityLabel
    }

    // MARK: - Touch: swell, droplet, slide to select

    @objc private func handlePress(_ gesture: UILongPressGestureRecognizer) {
        handlePress(state: gesture.state, at: gesture.location(in: self))
    }

    /// Gesture logic (separate so tests can drive it).
    func handlePress(state: UIGestureRecognizer.State, at point: CGPoint) {
        if handleActionPress(state: state, at: point) { return }
        if isMinimized {
            switch state {
            case .began: glass.setPressed(true, at: convert(point, to: glass))
            case .ended:
                glass.setPressed(false)
                onExpandRequest?()
            case .cancelled, .failed: glass.setPressed(false)
            default: break
            }
            return
        }
        guard appearance.droplet.isEnabled else {
            handlePlainPress(state: state, at: point)
            return
        }
        switch state {
        case .began:
            beginDroplet(at: point)
        case .changed:
            moveDroplet(to: point)
        case .ended:
            glass.setPressed(false)
            // Slid far above the bar: cancel, like the system.
            if point.y < -60 { cancelDroplet() } else { landDroplet() }
        case .cancelled, .failed:
            glass.setPressed(false)
            cancelDroplet()
        default:
            break
        }
    }

    /// Touches that start on the action button stay with it. Returns `true` if handled.
    private func handleActionPress(state: UIGestureRecognizer.State, at point: CGPoint) -> Bool {
        let inside = actionButton.frame.insetBy(dx: -6, dy: -6).contains(point)
        if state == .began {
            guard action != nil, !isMinimized, inside else { return false }
            isTrackingAction = true
            impact.prepare()
            actionButton.setPressed(true, at: convert(point, to: actionButton))
            return true
        }
        guard isTrackingAction else { return false }
        switch state {
        case .changed:
            actionButton.setPressed(inside, at: convert(point, to: actionButton))
        case .ended:
            isTrackingAction = false
            actionButton.setPressed(false)
            if inside {
                impact.impactOccurred()
                onAction?()
            }
        default:
            isTrackingAction = false
            actionButton.setPressed(false)
        }
        return true
    }

    /// No droplet: swell while pressed, select where the finger lifts.
    private func handlePlainPress(state: UIGestureRecognizer.State, at point: CGPoint) {
        switch state {
        case .began:
            glass.setPressed(true, at: convert(point, to: glass))
        case .changed:
            glass.movePressPoint(to: convert(point, to: glass))
        case .ended:
            glass.setPressed(false)
            if bounds.insetBy(dx: -20, dy: -40).contains(point) { onSelect?(index(atX: point.x)) }
        case .cancelled, .failed:
            glass.setPressed(false)
        default:
            break
        }
    }

    /// The tab under `x`. Over the action slot: the nearest tab next to it.
    func index(atX x: CGFloat) -> Int {
        let local = convert(CGPoint(x: x, y: bounds.midY), to: stack)
        guard !buttons.isEmpty, !slots.isEmpty else { return 0 }
        var slot = slots.firstIndex { local.x < $0.frame.maxX } ?? slots.count - 1
        if slots[slot] === actionSlot {
            let isLeftHalf = local.x < actionSlot.frame.midX
            slot = isLeftHalf && slot > 0 || slot == slots.count - 1 ? slot - 1 : slot + 1
        }
        return buttons.firstIndex { $0 === slots[slot] } ?? 0
    }

    /// Where the droplet center may go: the tab centers, with rubber band past the ends.
    private func clampedX(_ x: CGFloat) -> CGFloat {
        guard let first = buttons.first, let last = buttons.last else { return x }
        let minX = stack.convert(first.center, to: self).x
        let maxX = stack.convert(last.center, to: self).x
        if x < minX { return minX - (minX - x) * 0.25 }
        if x > maxX { return maxX + (x - maxX) * 0.25 }
        return x
    }

    private func beginDroplet(at point: CGPoint) {
        guard !buttons.isEmpty else { return }
        isDragging = true
        if appearance.haptics { haptics.prepare() }
        glass.setPressed(true, at: convert(point, to: glass))
        dragIndex = index(atX: point.x)
        lastDrag = (point.x, CACurrentMediaTime())

        droplet.prepare(items: renderItems(), itemsFrame: stack.convert(stack.bounds, to: self))
        let start = convert(tabFrame(for: selectedIndex).inset(by: appearance.selection.inset), from: glass.contentView)
        droplet.transform = .identity
        droplet.bounds = CGRect(origin: .zero, size: start.size)
        droplet.center = CGPoint(x: start.midX, y: start.midY)
        droplet.updateContent(center: droplet.center, magnification: 1)
        droplet.alpha = 1
        indicator.alpha = 0

        // Lift: the selection turns into a bigger lens and travels to the finger.
        let lift = appearance.droplet.lift
        let size = CGSize(width: start.width + lift.width, height: bounds.height + lift.height)
        let target = CGPoint(x: clampedX(point.x), y: bounds.midY)
        let magnification = appearance.droplet.magnification
        animate(damping: 0.62, duration: 0.45) {
            self.droplet.bounds = CGRect(origin: .zero, size: size)
            self.droplet.center = target
            self.droplet.updateContent(center: target, magnification: magnification)
        }
    }

    private func moveDroplet(to point: CGPoint) {
        guard isDragging else { return }
        let now = CACurrentMediaTime()
        let velocity = (point.x - lastDrag.x) / CGFloat(max(now - lastDrag.time, 1 / 120))
        lastDrag = (point.x, now)

        let x = clampedX(point.x)
        let index = index(atX: x)
        if index != dragIndex {
            dragIndex = index
            if appearance.haptics {
                haptics.selectionChanged()
                haptics.prepare()
            }
        }
        // Liquid: faster = longer and flatter.
        let maxStretch = appearance.droplet.maxStretch
        let stretch = UIAccessibility.isReduceMotionEnabled ? 1 : 1 + min(abs(velocity) / 2600, maxStretch)
        let center = CGPoint(x: x, y: bounds.midY)
        let magnification = appearance.droplet.magnification
        animate(damping: 0.8, duration: 0.25) {
            self.droplet.center = center
            self.droplet.transform = CGAffineTransform(scaleX: stretch, y: 1 / sqrt(stretch))
            self.droplet.updateContent(center: center, magnification: magnification)
        }
        glass.movePressPoint(to: convert(point, to: glass))
    }

    private func landDroplet() {
        guard isDragging else { return }
        onSelect?(index(atX: droplet.center.x))
        finishDroplet(bounce: true)
    }

    private func cancelDroplet() {
        guard isDragging else { return }
        finishDroplet(bounce: false)
    }

    /// Shrinks the droplet into the selected tab, then shows the indicator again.
    private func finishDroplet(bounce: Bool) {
        let index = selectedIndex
        let frame = convert(tabFrame(for: index).inset(by: appearance.selection.inset), from: glass.contentView)
        let center = CGPoint(x: frame.midX, y: frame.midY)
        indicator.frame = indicatorFrame(for: index)
        if bounce, appearance.selection.bouncesIcon, buttons.indices.contains(index), !UIAccessibility.isReduceMotionEnabled {
            buttons[index].bounce()
        }
        isDragging = false
        updateMinimizedIcon()
        animate(damping: 0.7, duration: 0.5) {
            self.droplet.transform = .identity
            self.droplet.bounds = CGRect(origin: .zero, size: frame.size)
            self.droplet.center = center
            self.droplet.updateContent(center: center, magnification: 1)
        } completion: {
            guard !self.isDragging else { return }
            UIView.animate(withDuration: 0.18, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
                self.droplet.alpha = 0
                self.indicator.alpha = self.isMinimized ? 0 : 1
            }
        }
    }

    /// The tabs drawn in the selected color: what the droplet magnifies.
    private func renderItems() -> UIImage {
        buttons.forEach { $0.showsAsSelected = true }
        defer { buttons.forEach { $0.showsAsSelected = false } }
        return UIGraphicsImageRenderer(bounds: stack.bounds).image { context in
            stack.layer.render(in: context.cgContext)
        }
    }

    private func animate(
        damping: CGFloat, duration: TimeInterval,
        _ changes: @escaping () -> Void, completion: (() -> Void)? = nil
    ) {
        guard window != nil, !UIAccessibility.isReduceMotionEnabled else {
            changes()
            completion?()
            return
        }
        UIView.animate(
            withDuration: duration, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: 0,
            options: [.beginFromCurrentState, .allowUserInteraction], animations: changes
        ) { _ in completion?() }
    }
}

extension LiquidGlassTabBar: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true // the large content viewer's long press
    }
}

extension LiquidGlassTabBar: UILargeContentViewerInteractionDelegate {
    func largeContentViewerInteraction(_ interaction: UILargeContentViewerInteraction, itemAt point: CGPoint) -> (any UILargeContentViewerItem)? {
        isMinimized || buttons.isEmpty ? nil : buttons[index(atX: point.x)]
    }

    func largeContentViewerInteraction(_ interaction: UILargeContentViewerInteraction, didEndOn item: (any UILargeContentViewerItem)?, at point: CGPoint) {
        guard let button = item as? LiquidGlassTabButton, let index = buttons.firstIndex(of: button) else { return }
        onSelect?(index)
    }
}

/// The glass lens that carries the selection while touching.
@MainActor
final class LiquidGlassDroplet: UIView {
    let glass = LiquidGlassView()
    let items = UIImageView()
    private var itemsFrame: CGRect = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        // Frosted, so only the magnified icons read (no double image), with rim light.
        glass.effects = [.specular, .motion]
        addSubview(glass)
        glass.contentView.addSubview(items)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported") // lint:allow – marked unavailable, can never be called
    }

    /// `itemsFrame`: where the tabs image sits, in the bar's coordinates.
    func prepare(items image: UIImage, itemsFrame: CGRect) {
        items.image = image
        self.itemsFrame = itemsFrame
    }

    /// Places the magnified tabs so the part under the lens lines up with the bar.
    /// `center` is the droplet center in the bar's coordinates.
    func updateContent(center: CGPoint, magnification: CGFloat) {
        let size = bounds.size
        glass.bounds = CGRect(origin: .zero, size: size)
        glass.center = CGPoint(x: size.width / 2, y: size.height / 2)
        items.frame = CGRect(
            x: (itemsFrame.minX - center.x) * magnification + size.width / 2,
            y: (itemsFrame.minY - center.y) * magnification + size.height / 2,
            width: itemsFrame.width * magnification,
            height: itemsFrame.height * magnification
        )
    }
}

/// One tab: icon over title, optional badge.
@MainActor
final class LiquidGlassTabButton: UIControl {
    /// VoiceOver double-tap.
    var onActivate: (() -> Void)?
    /// Draw in the selected color (for the droplet's magnified copy).
    var showsAsSelected = false {
        didSet { updateContent() }
    }

    private let imageView = UIImageView()
    let titleLabel = UILabel()
    let badge = UILabel()
    private let content = UIStackView()
    private var item: UITabBarItem?
    private var appearance = LiquidGlassTabBarAppearance.default
    private var tint: UIColor = .systemBlue

    /// The image shown now (selected image when selected).
    private(set) var currentImage: UIImage?

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFit
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8

        badge.font = .systemFont(ofSize: 11, weight: .semibold)
        badge.textAlignment = .center
        badge.layer.cornerRadius = 8
        badge.clipsToBounds = true
        badge.isHidden = true

        content.addArrangedSubview(imageView)
        content.addArrangedSubview(titleLabel)
        content.axis = .vertical
        content.alignment = .center
        content.isUserInteractionEnabled = false
        [content, badge].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        NSLayoutConstraint.activate([
            content.centerXAnchor.constraint(equalTo: centerXAnchor),
            content.centerYAnchor.constraint(equalTo: centerYAnchor),
            content.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 4),
            imageView.heightAnchor.constraint(greaterThanOrEqualToConstant: 24),
            badge.heightAnchor.constraint(equalToConstant: 16),
            badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 16),
            badge.centerXAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 2),
            badge.centerYAnchor.constraint(equalTo: imageView.topAnchor, constant: 2),
        ])

        isAccessibilityElement = true
        showsLargeContentViewer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported") // lint:allow – marked unavailable, can never be called
    }

    func apply(_ appearance: LiquidGlassTabBarAppearance, tint: UIColor) {
        self.appearance = appearance
        self.tint = tint
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: appearance.item.iconPointSize, weight: appearance.item.iconWeight
        )
        titleLabel.font = appearance.item.titleFont
        titleLabel.isHidden = !appearance.item.showsTitles
        content.spacing = appearance.item.spacing
        badge.backgroundColor = appearance.item.badgeColor
        badge.textColor = appearance.item.badgeTextColor
        updateContent()
    }

    /// Shows the current title, image and badge of the item again (after a change).
    func reloadItem() {
        if let item { configure(with: item) }
    }

    func configure(with item: UITabBarItem) {
        self.item = item
        titleLabel.text = item.title
        accessibilityLabel = item.title
        largeContentTitle = item.title
        largeContentImage = item.image
        if let value = item.badgeValue {
            badge.isHidden = false
            badge.text = value.isEmpty ? nil : " \(value) "
            accessibilityValue = value
        } else {
            badge.isHidden = true
            accessibilityValue = nil
        }
        updateContent()
    }

    override var isSelected: Bool {
        didSet { updateContent() }
    }

    override var accessibilityTraits: UIAccessibilityTraits {
        get { isSelected ? [.button, .selected] : .button }
        set { super.accessibilityTraits = newValue }
    }

    override func accessibilityActivate() -> Bool {
        onActivate?()
        return true
    }

    /// Small squash-and-stretch of the icon when its tab becomes selected.
    func bounce() {
        imageView.transform = CGAffineTransform(scaleX: 0.78, y: 0.78)
        UIView.animate(withDuration: 0.55, delay: 0, usingSpringWithDamping: 0.45, initialSpringVelocity: 0.8, options: [.allowUserInteraction]) {
            self.imageView.transform = .identity
        }
    }

    private func updateContent() {
        let selected = isSelected || showsAsSelected
        let selectedImage = appearance.item.usesSelectedImage ? item?.selectedImage : nil
        currentImage = selected ? (selectedImage ?? item?.image) : item?.image
        imageView.image = currentImage
        // The droplet copy is drawn in the accent color even with `.solid` (no pill behind it).
        let selectedColor = showsAsSelected && appearance.selection.style == .solid
            ? appearance.indicatorColor(tint: tint)
            : appearance.selectedItemColor(tint: tint)
        let color = selected ? selectedColor : appearance.item.normalColor
        imageView.tintColor = color
        titleLabel.textColor = color
    }
}
