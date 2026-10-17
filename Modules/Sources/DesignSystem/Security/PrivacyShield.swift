//
//  PrivacyShield.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import SwiftUI
import UIKit

/// Hides app content in the App Switcher snapshot (banking-style).
/// iOS takes the snapshot right after `sceneWillResignActive`.
///
///     // SceneDelegate
///     func sceneWillResignActive(_ scene: UIScene) { privacyShield.show(on: window) }
///     func sceneDidBecomeActive(_ scene: UIScene)  { privacyShield.hide() }
@MainActor
public final class PrivacyShield {
    private var overlay: UIView?

    /// Keep one instance per window.
    public init() {}

    /// Covers `window` with a blur.
    public func show(on window: UIWindow?) {
        guard let window, overlay == nil else { return }
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        blur.frame = window.bounds
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubview(blur)
        overlay = blur
    }

    /// Removes the blur.
    public func hide() {
        overlay?.removeFromSuperview()
        overlay = nil
    }
}

/// Copy sensitive text (OTP, account number) that expires and never syncs
/// to other devices through Universal Clipboard.
public enum SecurePasteboard {
    /// `SecurePasteboard.copy(otp, expiresAfter: 60)`
    @MainActor
    public static func copy(_ text: String, expiresAfter seconds: TimeInterval = 60) {
        UIPasteboard.general.setItems(
            [[UIPasteboard.typeAutomatic: text]],
            options: [
                .localOnly: true,
                .expirationDate: Date().addingTimeInterval(seconds),
            ]
        )
    }
}

/// Hides its content from screenshots and screen recording (uses the
/// secure text-field layer trick that iOS excludes from captures).
///
///     SecureContent { Text(cardNumber) }
public struct SecureContent<Content: View>: UIViewRepresentable {
    private let content: Content

    /// `SecureContent { Text(cardNumber) }`
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public func makeUIView(context: Context) -> UIView {
        let host = UIHostingController(rootView: content)
        host.view.backgroundColor = .clear
        context.coordinator.host = host

        let field = UITextField()
        field.isSecureTextEntry = true
        field.isUserInteractionEnabled = false
        // The secure field's internal canvas is excluded from captures.
        // If a future iOS changes this, fall back to showing the content normally.
        guard let secureLayer = field.subviews.first else { return host.view }
        secureLayer.subviews.forEach { $0.removeFromSuperview() }
        secureLayer.addSubview(host.view)
        host.view.pinEdges(to: secureLayer)
        return secureLayer
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.host?.rootView = content
    }

    public func makeCoordinator() -> Coordinator { Coordinator() }

    public final class Coordinator {
        var host: UIHostingController<Content>?
    }
}

public extension View {
    /// Applies the shield/secure-field approach to a whole subtree.
    func hiddenFromScreenCapture() -> some View {
        SecureContent { self }
    }
}
