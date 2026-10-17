//
//  UIKit+Layout.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import SwiftUI
import UIKit

public extension UIView {
    /// Pins all edges to the superview (or its safe area).
    func pinEdges(to other: UIView, insets: UIEdgeInsets = .zero, safeArea: Bool = false) {
        translatesAutoresizingMaskIntoConstraints = false
        let guide: any LayoutGuideAnchors = safeArea ? other.safeAreaLayoutGuide : other
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: guide.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -insets.right),
            bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -insets.bottom),
        ])
    }
}

/// Lets `pinEdges` accept a view or a layout guide.
@MainActor
public protocol LayoutGuideAnchors {
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
    var leadingAnchor: NSLayoutXAxisAnchor { get }
    var trailingAnchor: NSLayoutXAxisAnchor { get }
}

extension UIView: LayoutGuideAnchors {}
extension UILayoutGuide: LayoutGuideAnchors {}

public extension UITraitCollection {
    /// Same breakpoints idea as `LayoutClass`, for UIKit screens.
    var isRegularWidth: Bool { horizontalSizeClass == .regular }
}

public extension UIViewController {
    /// Layout class of this screen's current width (UIKit counterpart of `\.layoutClass`).
    var layoutClass: LayoutClass { LayoutClass(width: view.bounds.width) }

    /// Embeds a SwiftUI view inside a UIKit screen (e.g. a SwiftUI header
    /// in a Storyboard screen). The hosting controller is added as a child,
    /// so it is released together with this controller.
    @discardableResult
    func embed<Content: View>(_ view: Content, in container: UIView) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        host.view.backgroundColor = .clear
        addChild(host)
        container.addSubview(host.view)
        host.view.pinEdges(to: container)
        host.didMove(toParent: self)
        return host
    }
}

public extension UIViewController {
    /// Shows any view controller (Storyboard, VIPER builder output...) in a SwiftUI `#Preview`:
    ///
    ///     #Preview { ProfileBuilder.build(router: PreviewRouter()).asPreview() }
    func asPreview() -> some View {
        ViewControllerPreview(viewController: self)
    }
}

private struct ViewControllerPreview: UIViewControllerRepresentable {
    let viewController: UIViewController

    func makeUIViewController(context: Context) -> UINavigationController {
        UINavigationController(rootViewController: viewController)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
