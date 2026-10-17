//
//  Keyboard.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Observation
import UIKit

/// App-wide keyboard helpers. One place for everything keyboard:
///
/// | Need | API |
/// |---|---|
/// | Hide it from anywhere | `Keyboard.dismiss()` |
/// | Tap outside a field hides it, whole app | `Keyboard.enableTapToDismiss(in: window)` (done by `AppCoordinator`) |
/// | Know its height / visibility | `KeyboardObserver.shared.height`, `.isVisible` |
/// | SwiftUI forms | `.focusNext(_:to:)`, `.keyboardDoneButton()`, `.dismissKeyboardOnTap()`, `.keyboardPadding()` |
/// | UIKit screens | `scrollView.adjustsForKeyboard()`, `view.pinAboveKeyboard(_:)`, `TextFieldChain` |
@MainActor
public enum Keyboard {
    /// Hides the keyboard wherever it is: `Keyboard.dismiss()`.
    public static func dismiss() {
        // UIApplication only exists inside an app (not in package unit tests).
        guard Bundle.main.bundleURL.pathExtension == "app" else { return }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    /// Tapping anywhere outside a text field hides the keyboard, on every screen
    /// of `window`. Taps still reach buttons and cells (`cancelsTouchesInView = false`).
    public static func enableTapToDismiss(in window: UIWindow) {
        guard objc_getAssociatedObject(window, &TapToDismiss.key) == nil else { return }
        let handler = TapToDismiss(window: window)
        objc_setAssociatedObject(window, &TapToDismiss.key, handler, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

/// Live keyboard state for SwiftUI (`@Observable`) and UIKit (`onChange`).
///
///     Text("Keyboard: \(Int(KeyboardObserver.shared.height)) pt")
///     KeyboardObserver.shared.onChange = { height in ... }
@MainActor
@Observable
public final class KeyboardObserver {
    public static let shared = KeyboardObserver()

    /// Visible height in points (0 when hidden).
    public private(set) var height: CGFloat = 0
    /// Duration of the system animation, to move your views in sync.
    public private(set) var animationDuration: TimeInterval = 0.25
    public var isVisible: Bool { height > 0 }
    @ObservationIgnored public var onChange: ((CGFloat) -> Void)?

    @ObservationIgnored private var tokens: [any NSObjectProtocol] = []

    /// Separate observer for tests: `KeyboardObserver(center: NotificationCenter())`.
    public init(center: NotificationCenter = .default) {
        let names = [UIResponder.keyboardWillChangeFrameNotification, UIResponder.keyboardWillHideNotification]
        tokens = names.map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] notification in
                let info = KeyboardInfo(notification)
                // Delivered on the main queue (queue: .main).
                MainActor.assumeIsolated { self?.update(info) }
            }
        }
    }

    func update(_ info: KeyboardInfo) {
        animationDuration = info.duration
        height = info.isHiding ? 0 : info.visibleHeight
        onChange?(height)
    }
}

/// Values read from a keyboard notification (Sendable, so it can cross actors).
struct KeyboardInfo: Sendable {
    let visibleHeight: CGFloat
    let duration: TimeInterval
    let isHiding: Bool

    init(visibleHeight: CGFloat, duration: TimeInterval, isHiding: Bool) {
        self.visibleHeight = visibleHeight
        self.duration = duration
        self.isHiding = isHiding
    }

    init(_ notification: Notification) {
        let frame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        self.init(
            visibleHeight: max(0, frame.height),
            duration: notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25,
            isHiding: notification.name == UIResponder.keyboardWillHideNotification
        )
    }
}

/// Window-level tap recognizer that ends editing without stealing taps.
final class TapToDismiss: NSObject, UIGestureRecognizerDelegate {
    nonisolated(unsafe) static var key: UInt8 = 0
    private weak var window: UIWindow?

    init(window: UIWindow) {
        self.window = window
        super.init()
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        window.addGestureRecognizer(tap)
    }

    @objc func handleTap() {
        window?.endEditing(true)
    }

    /// Taps on text inputs keep the keyboard (moving between fields).
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        !Self.isTextInput(touch.view)
    }

    static func isTextInput(_ view: UIView?) -> Bool {
        var current = view
        while let view = current {
            if view is UITextField || view is UITextView || view is UISearchBar { return true }
            current = view.superview
        }
        return false
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }
}
