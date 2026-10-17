//
//  LiquidGlassTabBarController.swift
//  LiquidGlassKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import UIKit

/// A `UITabBarController` with an iOS 26-style floating Liquid Glass tab bar,
/// on iOS 17 and later. Drop-in: use it like any tab bar controller.
///
///     let tabs = LiquidGlassTabBarController()        // glass below iOS 26, system bar on 26
///     tabs.viewControllers = [homeNav, inboxNav]      // tabBarItem as usual
///     tabs.tabBar.tintColor = .systemPurple           // accent of the glass bar too
///     tabs.appearance = .tinted                        // or any custom look
///     tabs.minimizeBehavior = .onScrollDown           // optional, like iOS 26
///
/// Switch back to UIKit's bar with `style: .system`; nothing else changes.
/// `viewControllers`, `selectedIndex`, `delegate` (`shouldSelect`/`didSelect`),
/// `tabBarItem` title, image, selected image and badge (live) all work, and a
/// tap on the current tab pops it to its root. Screens scroll under the glass:
/// their bottom safe area includes the bar.
@MainActor
open class LiquidGlassTabBarController: UITabBarController {
    /// Which tab bar is shown.
    public enum Style: Sendable, Equatable {
        /// UIKit's tab bar (Liquid Glass on iOS 26, classic before).
        case system
        /// This kit's glass bar, on every version.
        case glass

        /// `style` before iOS 26, `.system` from iOS 26 (already Liquid Glass).
        @MainActor
        public static func belowIOS26(_ style: Style) -> Style {
            select(style, systemIsGlass: LiquidGlass.isSystemDesign)
        }

        static func select(_ style: Style, systemIsGlass: Bool) -> Style {
            systemIsGlass ? .system : style
        }
    }

    /// When the bar shrinks to a small circle (iOS 26 `tabBarMinimizeBehavior`).
    /// Turn it off with `.never` if your UX prefers a bar that always stays.
    public enum MinimizeBehavior: Sendable, Equatable, CaseIterable {
        /// Always full size (default).
        case never
        /// Shrinks while scrolling down; scroll up or tap to expand.
        case onScrollDown
        /// Shrinks while scrolling up (content that grows upward, like chats).
        case onScrollUp
    }

    /// Resolved style (`.belowIOS26(...)` is already decided here).
    public let style: Style

    /// How the glass bar looks. Assign any time; changes apply at once.
    public var appearance = LiquidGlassTabBarAppearance.default {
        didSet {
            glassBar?.apply(appearance)
            viewIfLoaded?.setNeedsLayout()
        }
    }

    /// Shrink the bar on scroll. Also applied to the system bar on iOS 26.
    /// Changing it at runtime is fine (e.g. from a Settings toggle).
    public var minimizeBehavior: MinimizeBehavior = .never {
        didSet {
            applySystemMinimizeBehavior()
            if minimizeBehavior == .never { setMinimized(false, animated: true) }
        }
    }

    /// A button that is not a tab (camera, compose...): runs its handler
    /// instead of switching screens. `nil` = none.
    public var actionButton: LiquidGlassTabBarAction? {
        didSet { actionButtonChanged() }
    }

    /// A glass strip above the bar for something always at hand (mini player,
    /// upload progress...), like iOS 26's `bottomAccessory`. When the bar
    /// minimizes, it moves next to it. iOS 26 system bar: `UITabAccessory`.
    public var accessoryView: UIView? {
        didSet { accessoryChanged(old: oldValue) }
    }

    /// Height of `accessoryView`'s glass strip.
    public var accessoryHeight: CGFloat = 48 {
        didSet { viewIfLoaded?.setNeedsLayout() }
    }

    /// The glass bar, `nil` with `.system`.
    private(set) var glassBar: LiquidGlassTabBar?
    private(set) var accessoryHost: LiquidGlassView?
    /// The action button floating above the system bar (`.system` style).
    private(set) var floatingActionButton: LiquidGlassActionButton?
    private var isGlassBarHidden = false
    private weak var trackedScrollView: UIScrollView?
    private var scrollObservation: NSKeyValueObservation?
    private var lastScrollY: CGFloat = 0
    private var scrollTravel: CGFloat = 0

    public init(style: Style = .belowIOS26(.glass)) {
        self.style = style
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported") // lint:allow – marked unavailable, can never be called
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        applySystemMinimizeBehavior()
        guard style == .glass else { return }
        if #available(iOS 18, *) {
            setTabBarHidden(true, animated: false)
        }
        tabBar.isHidden = true

        let bar = LiquidGlassTabBar()
        bar.apply(appearance)
        bar.onSelect = { [weak self] index in self?.userSelected(index) }
        bar.onExpandRequest = { [weak self] in self?.setMinimized(false, animated: true) }
        bar.onAction = { [weak self] in self?.runAction() }
        view.addSubview(bar)
        glassBar = bar
        reloadGlassItems()
        actionButtonChanged()
        accessoryChanged(old: nil)
    }

    private func accessoryChanged(old: UIView?) {
        guard isViewLoaded else { return }
        old?.removeFromSuperview()
        if style == .system, LiquidGlass.isSystemDesign, #available(iOS 26, *) {
            bottomAccessory = accessoryView.map { UITabAccessory(contentView: $0) }
            return
        }
        guard let accessoryView else {
            accessoryHost?.removeFromSuperview()
            accessoryHost = nil
            view.setNeedsLayout()
            return
        }
        let host = accessoryHost ?? LiquidGlassView()
        if accessoryHost == nil {
            host.effects = [.specular, .motion, .refraction]
            view.addSubview(host)
            accessoryHost = host
        }
        host.backdrop = selectedViewController?.view
        accessoryView.frame = host.contentView.bounds
        accessoryView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.contentView.addSubview(accessoryView)
        view.setNeedsLayout()
    }

    /// Above the full bar; next to the minimized one; above UIKit's bar with `.system`.
    private func layoutAccessory() {
        guard let host = accessoryHost else { return }
        let height = accessoryHeight
        let frame: CGRect
        if let glassBar {
            let bar = barFrame(for: glassBar)
            if glassBar.isMinimized {
                let margin = appearance.bar.horizontalMargin
                let maxX = view.bounds.maxX - view.safeAreaInsets.right - margin
                frame = CGRect(x: bar.maxX + 8, y: bar.midY - height / 2, width: max(maxX - bar.maxX - 8, 0), height: height)
            } else {
                let width = max(bar.width, min(view.bounds.width - 32, 340))
                frame = CGRect(x: view.bounds.midX - width / 2, y: bar.minY - 8 - height, width: width, height: height)
            }
        } else {
            frame = CGRect(x: 16, y: tabBar.frame.minY - 8 - height, width: view.bounds.width - 32, height: height)
        }
        host.frame = frame
        view.bringSubviewToFront(host)
    }

    /// Runs the action button's handler (also what a tap does).
    public func runAction() {
        actionButton?.handler(self)
    }

    private func actionButtonChanged() {
        guard isViewLoaded else { return }
        if let glassBar {
            glassBar.setAction(actionButton)
        } else if let action = actionButton {
            // UIKit's bar cannot hold custom views: float the button just above it.
            let button = floatingActionButton ?? LiquidGlassActionButton()
            if floatingActionButton == nil {
                button.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(floatingActionTapped)))
                button.onTap = { [weak self] in self?.runAction() }
                view.addSubview(button)
                floatingActionButton = button
            }
            button.configure(with: action, tint: tabBar.tintColor ?? view.tintColor)
        } else {
            floatingActionButton?.removeFromSuperview()
            floatingActionButton = nil
        }
        view.setNeedsLayout()
    }

    @objc private func floatingActionTapped() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        runAction()
    }

    override open var viewControllers: [UIViewController]? {
        didSet { reloadGlassItems() }
    }

    override open func setViewControllers(_ viewControllers: [UIViewController]?, animated: Bool) {
        super.setViewControllers(viewControllers, animated: animated)
        reloadGlassItems()
    }

    override open var selectedIndex: Int {
        didSet { selectionChanged() }
    }

    override open var selectedViewController: UIViewController? {
        didSet { selectionChanged() }
    }

    /// Hides the glass bar (e.g. full-screen media). With `.system`, use UIKit's API.
    public func setGlassBarHidden(_ hidden: Bool, animated: Bool) {
        guard let glassBar, hidden != isGlassBarHidden else { return }
        isGlassBarHidden = hidden
        let changes = {
            glassBar.alpha = hidden ? 0 : 1
            glassBar.transform = hidden ? CGAffineTransform(translationX: 0, y: glassBar.bounds.height + 20) : .identity
        }
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0, animations: changes)
        } else {
            changes()
        }
        view.setNeedsLayout()
    }

    /// The visible screen is changing (push/pop inside a tab). Keeps the glass
    /// live during the transition and follows the new screen's scroll view.
    /// Call it from your `UINavigationControllerDelegate.willShow`.
    public func contentWillChange() {
        glassBar?.glass.setNeedsBackdropUpdate(duration: 0.6)
        setMinimized(false, animated: true)
        // The new screen's scroll view exists once the push has started.
        DispatchQueue.main.async { [weak self] in self?.trackScrollView() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in self?.trackScrollView() }
    }

    // MARK: - Layout

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutFloatingActionButton()
        guard let glassBar else {
            layoutAccessory()
            return
        }
        if !tabBar.isHidden { tabBar.isHidden = true }
        if glassBar.tintColor != tabBar.tintColor { glassBar.tintColor = tabBar.tintColor }
        glassBar.frame = barFrame(for: glassBar)
        view.bringSubviewToFront(glassBar)

        layoutAccessory()

        // Content scrolls under the glass, and its last row stays reachable above it.
        let accessory = accessoryHost == nil ? 0 : accessoryHeight + 8
        let covered = isGlassBarHidden ? 0 : bottomSpacing + appearance.bar.height + 8 + accessory - view.safeAreaInsets.bottom
        for child in viewControllers ?? [] where child.additionalSafeAreaInsets.bottom != covered {
            child.additionalSafeAreaInsets.bottom = covered
        }
        if glassBar.glass.backdrop == nil { selectionChanged() }
    }

    private func layoutFloatingActionButton() {
        guard let button = floatingActionButton, let action = actionButton else { return }
        // The app sets `tabBar.tintColor` after creating us: follow it.
        button.configure(with: action, tint: tabBar.tintColor ?? view.tintColor)
        let size = action.style == .raised ? action.raisedSize : 48
        let barTop = tabBar.isHidden ? view.bounds.maxY - view.safeAreaInsets.bottom : tabBar.frame.minY
        let x: CGFloat
        switch action.placement {
        case .leading: x = view.safeAreaInsets.left + 16 + size / 2
        case .trailing: x = view.bounds.maxX - view.safeAreaInsets.right - 16 - size / 2
        case .center, .index: x = view.bounds.midX
        }
        button.bounds = CGRect(x: 0, y: 0, width: size, height: size)
        button.center = CGPoint(x: x, y: barTop - 12 - size / 2)
        view.bringSubviewToFront(button)
    }

    /// iOS 26 sits the bar just above the home indicator; 12 pt on Touch ID phones.
    private var bottomSpacing: CGFloat {
        if let spacing = appearance.bar.bottomSpacing { return spacing }
        let homeIndicator = view.safeAreaInsets.bottom
        return homeIndicator > 0 ? max(homeIndicator - 13, 8) : 12
    }

    private func barFrame(for bar: LiquidGlassTabBar) -> CGRect {
        let bounds = view.bounds
        let insets = view.safeAreaInsets
        let margin = appearance.bar.horizontalMargin
        let height = bar.preferredHeight
        let y = bounds.maxY - bottomSpacing - height
        if bar.isMinimized {
            // A circle at the leading edge, bottom aligned with the full bar.
            let leading = view.effectiveUserInterfaceLayoutDirection == .rightToLeft
                ? bounds.maxX - insets.right - margin - height
                : insets.left + margin
            return CGRect(x: leading, y: y, width: height, height: height)
        }
        let width = bar.preferredWidth(maxWidth: bounds.width - insets.left - insets.right - margin * 2)
        return CGRect(x: bounds.midX - width / 2, y: y, width: width, height: height)
    }

    // MARK: - Minimize

    /// `true` while the glass bar is the small circle.
    public var isMinimized: Bool { glassBar?.isMinimized ?? false }

    /// Shrinks or expands the glass bar yourself (any `minimizeBehavior`),
    /// e.g. while a video plays. No effect with `.system`.
    public func setMinimized(_ minimized: Bool, animated: Bool) {
        guard let glassBar, glassBar.isMinimized != minimized else { return }
        let changes = {
            glassBar.setMinimized(minimized)
            glassBar.frame = self.barFrame(for: glassBar)
            glassBar.layoutIfNeeded()
            self.layoutAccessory()
            self.accessoryHost?.layoutIfNeeded()
        }
        guard animated, view.window != nil, !UIAccessibility.isReduceMotionEnabled else {
            changes()
            return
        }
        UIView.animate(
            withDuration: 0.55, delay: 0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0,
            options: [.beginFromCurrentState, .allowUserInteraction], animations: changes
        )
    }

    private func applySystemMinimizeBehavior() {
        guard style == .system else { return }
        if #available(iOS 26, *) {
            switch minimizeBehavior {
            case .never: tabBarMinimizeBehavior = .never
            case .onScrollDown: tabBarMinimizeBehavior = .onScrollDown
            case .onScrollUp: tabBarMinimizeBehavior = .onScrollUp
            }
        }
    }

    // MARK: - Scroll tracking (refraction + minimize)

    private func selectionChanged() {
        guard let glassBar else { return }
        glassBar.select(selectedIndex, animated: viewIfLoaded?.window != nil)
        glassBar.glass.backdrop = selectedViewController?.view
        accessoryHost?.backdrop = selectedViewController?.view
        glassBar.glass.setNeedsBackdropUpdate(duration: 0.4)
        setMinimized(false, animated: true)
        trackScrollView()
    }

    /// Follows the main scroll view of the visible screen.
    func trackScrollView() {
        guard glassBar != nil else { return }
        let screen = (selectedViewController as? UINavigationController)?.topViewController ?? selectedViewController
        let scrollView = screen.flatMap { Self.mainScrollView(in: $0.view) }
        guard scrollView !== trackedScrollView else { return }
        trackedScrollView = scrollView
        scrollTravel = 0
        lastScrollY = scrollView.map { $0.contentOffset.y + $0.adjustedContentInset.top } ?? 0
        scrollObservation = scrollView?.observe(\.contentOffset, options: [.new]) { [weak self] scrollView, _ in
            MainActor.assumeIsolated { self?.scrollViewDidScroll(scrollView) }
        }
    }

    /// The largest vertically scrolling view (SwiftUI `ScrollView`/`List` are UIScrollViews too).
    static func mainScrollView(in root: UIView?) -> UIScrollView? {
        guard let root else { return nil }
        var best: UIScrollView?
        var queue = [root]
        while !queue.isEmpty {
            let view = queue.removeFirst()
            if let scroll = view as? UIScrollView, !scroll.isHidden, !scroll.alwaysBounceHorizontal,
               scroll.bounds.width * scroll.bounds.height > (best.map { $0.bounds.width * $0.bounds.height } ?? 0),
               scroll.bounds.height > root.bounds.height * 0.4 {
                best = scroll
                continue // nested ones are rows, carousels...
            }
            queue.append(contentsOf: view.subviews)
        }
        return best
    }

    private func scrollViewDidScroll(_ scrollView: UIScrollView) {
        glassBar?.glass.setNeedsBackdropUpdate(duration: 0.25)
        let inset = scrollView.adjustedContentInset
        handleScroll(
            offset: scrollView.contentOffset.y + inset.top,
            isScrollable: scrollView.contentSize.height > scrollView.bounds.height - inset.top - inset.bottom,
            isUserScrolling: scrollView.isTracking || scrollView.isDecelerating
        )
    }

    /// Minimize rule: 28 pt in the shrinking direction = shrink, 16 pt back
    /// (or reaching the top, for `.onScrollDown`) = expand.
    func handleScroll(offset y: CGFloat, isScrollable: Bool, isUserScrolling: Bool) {
        let delta = y - lastScrollY
        lastScrollY = y
        guard minimizeBehavior != .never, glassBar != nil, isScrollable, isUserScrolling else { return }
        if minimizeBehavior == .onScrollDown, y <= 8 {
            setMinimized(false, animated: true)
            scrollTravel = 0
            return
        }
        // Positive = toward shrinking. Direction changes reset the distance; small jitters do nothing.
        let step = minimizeBehavior == .onScrollDown ? delta : -delta
        scrollTravel = (scrollTravel >= 0) == (step >= 0) ? scrollTravel + step : step
        if scrollTravel > 28 {
            setMinimized(true, animated: true)
        } else if scrollTravel < -16 {
            setMinimized(false, animated: true)
        }
    }

    // MARK: - Private

    private func reloadGlassItems() {
        guard let glassBar else { return }
        glassBar.setItems((viewControllers ?? []).map(\.tabBarItem))
        glassBar.select(selectedIndex, animated: false)
        view.setNeedsLayout()
    }

    /// Same rules as a tap on the system bar.
    func userSelected(_ index: Int) {
        guard let controllers = viewControllers, controllers.indices.contains(index) else { return }
        let target = controllers[index]
        if delegate?.tabBarController?(self, shouldSelect: target) == false { return }
        if target === selectedViewController {
            // Second tap on the current tab: back to its first screen.
            (target as? UINavigationController)?.popToRootViewController(animated: true)
        } else {
            selectedViewController = target
        }
        delegate?.tabBarController?(self, didSelect: target)
    }
}
