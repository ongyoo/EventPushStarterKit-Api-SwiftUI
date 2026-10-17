//
//  Coordinator.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import UIKit

/// Owns a navigation flow: creates screens, decides where to go next,
/// handles deep links. Screens never navigate by themselves.
///
/// Memory rules (enforced by this class):
/// - A parent keeps its children in `children` (strong).
/// - A child never keeps its parent (only the `onFinish` closure, which
///   the parent creates with `[weak self]`).
/// - When the child's first screen is popped (back button / swipe),
///   `Navigator` calls `finish()` and the parent drops the child.
/// - After dropping, `LeakDetector` warns if the child is still alive.
@MainActor
open class Coordinator {
    /// The navigation stack this flow pushes on.
    public let navigator: Navigator
    public private(set) var children: [Coordinator] = []

    /// Set by the parent. Called by `finish()`.
    fileprivate var onFinish: (() -> Void)?

    /// Children usually share the parent's navigator: `Child(navigator: navigator)`.
    public init(navigator: Navigator) {
        self.navigator = navigator
    }

    /// Show the first screen of the flow. Override in subclasses.
    open func start() {}

    /// Try to handle the deep link. Consume the path segments you understand
    /// and pass the rest to a child (`child.handle(link.dropFirst())`).
    /// Return `false` if the link is not for this coordinator.
    @discardableResult
    open func handle(_ link: DeepLink) -> Bool {
        false
    }

    /// Shows the flow's first screen.
    /// - `asRoot: true`  -> replaces the stack (tab root). Never finishes by popping.
    /// - `asRoot: false` -> pushes; when the user pops it, the flow finishes
    ///   and the parent releases this coordinator.
    public func showFirstScreen(
        _ viewController: UIViewController,
        asRoot: Bool,
        transition: Transition = .system,
        animated: Bool = true
    ) {
        if asRoot {
            navigator.setRoot(viewController)
        } else {
            navigator.push(viewController, transition: transition, animated: animated) { [weak self] in
                self?.finish()
            }
        }
    }

    /// Starts a child flow and keeps it alive until it finishes.
    public func startChild(_ child: Coordinator) {
        children.append(child)
        child.onFinish = { [weak self, weak child] in
            guard let self, let child else { return }
            self.removeChild(child)
        }
        Log.navigation.debug("start \(String(describing: type(of: child)))")
        child.start()
    }

    /// Ends this flow. The parent removes it from `children`.
    public func finish() {
        children.forEach { $0.finish() }
        onFinish?()
        onFinish = nil
    }

    /// Starts a child flow in a modal with its OWN navigation stack.
    /// The child is released when the modal is dismissed (button or swipe).
    ///
    ///     presentChild(style: .sheet(detents: [.medium])) { navigator in
    ///         CheckoutCoordinator(navigator: navigator)
    ///     }
    ///
    /// Inside the child, call `dismissFlow()` to close it.
    @discardableResult
    public func presentChild<Child: Coordinator>(
        style: PresentationStyle = .sheet(),
        transition: Transition = .system,
        make: (Navigator) -> Child
    ) -> Child {
        let modalNavigator = Navigator()
        let child = make(modalNavigator)
        startChild(child)
        navigator.present(modalNavigator.navigationController, style: style, transition: transition) { [weak child] in
            child?.finish()
        }
        return child
    }

    /// Closes a flow started with `presentChild` (runs `finish()` via onDismiss).
    public func dismissFlow(animated: Bool = true) {
        guard let presenter = navigator.navigationController.presentingViewController else {
            finish()
            return
        }
        presenter.dismiss(animated: animated) { [weak self] in
            self?.finish()
        }
    }

    /// Finishes and removes every child (e.g. before handling a deep link).
    public func removeAllChildren() {
        children.forEach { $0.finish() }
        children.removeAll()
    }

    private func removeChild(_ child: Coordinator) {
        children.removeAll { $0 === child }
        Log.navigation.debug("finish \(String(describing: type(of: child)))")
        LeakDetector.expectDeallocation(of: child)
    }

    #if DEBUG
    deinit {
        print("♻️ deinit \(type(of: self))")
    }
    #endif
}

/// Root coordinator of a tab or window: it is never popped.
/// Subclasses usually override `start()` with `navigator.setRoot(...)`.
@MainActor
open class FlowCoordinator: Coordinator {
    /// The navigation controller to put in a tab / window.
    public var rootViewController: UINavigationController { navigator.navigationController }
}
