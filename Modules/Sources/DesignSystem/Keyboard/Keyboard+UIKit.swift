//
//  Keyboard+UIKit.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import UIKit

public extension UIScrollView {
    /// Keeps content visible above the keyboard: adjusts the bottom inset and
    /// scrolls the focused field into view. Call once (e.g. in `viewDidLoad`).
    ///
    ///     tableView.adjustsForKeyboard()
    ///     tableView.keyboardDismissMode = .interactive   // swipe down to hide
    func adjustsForKeyboard(observer: KeyboardObserver = .shared) {
        guard objc_getAssociatedObject(self, &KeyboardScrollAdjuster.key) == nil else { return }
        let adjuster = KeyboardScrollAdjuster(scrollView: self, observer: observer)
        objc_setAssociatedObject(self, &KeyboardScrollAdjuster.key, adjuster, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

public extension UIView {
    /// Pins `subview` (a bottom bar, a send button...) just above the keyboard,
    /// or above the safe area when the keyboard is hidden. Uses `keyboardLayoutGuide`.
    ///
    ///     view.pinAboveKeyboard(composerBar, spacing: 8)
    func pinAboveKeyboard(_ subview: UIView, spacing: CGFloat = 0) {
        if subview.superview !== self { addSubview(subview) }
        subview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subview.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            subview.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            subview.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor, constant: -spacing),
        ])
    }
}

/// Return key moves through text fields in order; the last one hides the keyboard.
///
///     private var chain: TextFieldChain?
///     chain = TextFieldChain([nameField, emailField, passwordField]) { [weak self] in self?.submit() }
@MainActor
public final class TextFieldChain {
    private let fields: [UITextField]
    private let onDone: (() -> Void)?

    public init(_ fields: [UITextField], onDone: (() -> Void)? = nil) {
        self.fields = fields
        self.onDone = onDone
        for (index, field) in fields.enumerated() {
            let isLast = index == fields.count - 1
            field.returnKeyType = isLast ? .done : .next
            field.addAction(UIAction { [weak self] _ in self?.didReturn(from: index) }, for: .editingDidEndOnExit)
        }
    }

    func didReturn(from index: Int) {
        if index + 1 < fields.count {
            fields[index + 1].becomeFirstResponder()
        } else {
            fields[index].resignFirstResponder()
            onDone?()
        }
    }
}

/// Retained by its scroll view (associated object): lives exactly as long as it.
@MainActor
final class KeyboardScrollAdjuster {
    nonisolated(unsafe) static var key: UInt8 = 0
    private weak var scrollView: UIScrollView?
    private let baseInset: CGFloat

    init(scrollView: UIScrollView, observer: KeyboardObserver) {
        self.scrollView = scrollView
        self.baseInset = scrollView.contentInset.bottom
        let previous = observer.onChange
        observer.onChange = { [weak self] height in
            previous?(height)
            self?.apply(keyboardHeight: height, duration: observer.animationDuration)
        }
    }

    func apply(keyboardHeight: CGFloat, duration: TimeInterval) {
        guard let scrollView else { return }
        // Only the part of the keyboard that covers the scroll view counts.
        let covered = max(0, keyboardHeight - scrollView.safeAreaInsets.bottom)
        UIView.animate(withDuration: duration) {
            scrollView.contentInset.bottom = self.baseInset + covered
            scrollView.verticalScrollIndicatorInsets.bottom = covered
        }
        if keyboardHeight > 0, let field = scrollView.firstResponderDescendant {
            scrollView.scrollRectToVisible(field.convert(field.bounds, to: scrollView).insetBy(dx: 0, dy: -16), animated: true)
        }
    }
}

extension UIView {
    /// The text field / view currently editing inside this view, if any.
    var firstResponderDescendant: UIView? {
        if isFirstResponder { return self }
        for subview in subviews {
            if let responder = subview.firstResponderDescendant { return responder }
        }
        return nil
    }
}
