//
//  NavigationBarHiding.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import UIKit

/// A screen that draws its own header adopts this to hide the navigation bar.
/// Every other screen shows it (with its back button).
///
/// `Navigator` applies it each time a screen is about to appear, so the bar
/// comes back automatically when you push a normal screen on top, and hides
/// again when you go back. Never hide the bar from inside a screen
/// (`.toolbar(.hidden, for: .navigationBar)`, `setNavigationBarHidden`): the bar
/// belongs to the whole stack, and the next screen would lose its back button.
///
///     HostingController(rootView: HomeView(...), hidesNavigationBar: true)
@MainActor
public protocol NavigationBarHiding: UIViewController {
    var prefersNavigationBarHidden: Bool { get }
}
