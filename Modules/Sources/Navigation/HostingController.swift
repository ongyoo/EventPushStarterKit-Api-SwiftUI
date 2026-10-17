//
//  HostingController.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import SwiftUI
import UIKit

/// Hosting controller for SwiftUI screens pushed by coordinators.
/// Sets the title and logs deallocation in Debug (helps spot leaks).
public final class HostingController<Content: View>: UIHostingController<Content>, NavigationBarHiding, AnalyticsScreenNaming, BackButtonStyling {
    public let prefersNavigationBarHidden: Bool
    /// Back button look while this screen is on top. `nil` = the navigator's.
    public let preferredBackButtonStyle: BackButtonStyle?
    /// `screen_view` name. Default: from the root view type (`HomeView` -> `home`).
    public let analyticsScreenName: String

    /// `HostingController(rootView: ProfileView(presenter: p), title: "Profile")`
    /// - Parameter hidesNavigationBar: `true` only for screens that draw their own
    ///   header (e.g. Home). Screens pushed on top get the bar and back button back.
    /// - Parameter backButton: this screen's back button look, e.g.
    ///   `.belowIOS26(.circle())` over a photo. `nil` = the navigator's.
    /// - Parameter screenName: analytics name, when the type name is not a good one.
    public init(
        rootView: Content,
        title: String? = nil,
        largeTitle: Bool = false,
        hidesNavigationBar: Bool = false,
        backButton: BackButtonStyle? = nil,
        screenName: String? = nil
    ) {
        self.prefersNavigationBarHidden = hidesNavigationBar
        self.preferredBackButtonStyle = backButton
        self.analyticsScreenName = screenName ?? ScreenName.from(typeName: String(describing: Content.self))
        super.init(rootView: rootView)
        self.title = title
        navigationItem.largeTitleDisplayMode = largeTitle ? .always : .never
    }

    @available(*, unavailable)
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported") // lint:allow – marked unavailable, can never be called
    }

    #if DEBUG
    deinit {
        print("♻️ deinit HostingController<\(Content.self)>")
    }
    #endif
}
