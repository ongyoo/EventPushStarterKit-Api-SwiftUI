//
//  ScreenTrackingTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Core
@testable import Navigation
import SwiftUI
import Testing
import UIKit

private struct ProfileView: View {
    var body: some View { Text("Profile") }
}

private final class CheckoutViewController: UIViewController, AnalyticsScreenNaming {
    let analyticsScreenName = "checkout"
}

@MainActor
struct ScreenTrackingTests {
    @Test func namesComeFromTypes() {
        #expect(ScreenName.from(typeName: "EventDetailView") == "event_detail")
        #expect(ScreenName.from(typeName: "NotificationViewController") == "notification")
        #expect(ScreenName.from(typeName: "HomeScreen") == "home")
        #expect(ScreenName.from(typeName: "ModifiedContent<HomeView, _PaddingLayout>") == "modified_content")
        #expect(ScreenName.from(typeName: "View") == "view")
        #expect(ScreenName.from(typeName: "URLSettingsView") == "url_settings")
        #expect(ScreenName.from(typeName: "Step2Screen") == "step2")
        #expect(ScreenName.from(typeName: "") == "screen")
        #expect(HostingController(rootView: ProfileView()).analyticsScreenName == "profile")
        #expect(HostingController(rootView: ProfileView(), screenName: "me").analyticsScreenName == "me")
        #expect(CheckoutViewController().resolvedAnalyticsScreenName == "checkout")
        #expect(UIViewController().resolvedAnalyticsScreenName == "ui")
    }

    @Test func navigatorReportsEachScreenOnce() {
        let analytics = RecordingAnalytics()
        let navigator = Navigator(analytics: analytics)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = navigator.navigationController
        window.makeKeyAndVisible()

        let nav = navigator.navigationController
        let home = HostingController(rootView: ProfileView(), screenName: "home")
        navigator.setRoot(home, animated: false)
        nav.delegate?.navigationController?(nav, didShow: home, animated: false)
        nav.delegate?.navigationController?(nav, didShow: home, animated: false)   // same screen again: ignored
        let checkout = CheckoutViewController()
        navigator.push(checkout, animated: false)
        nav.delegate?.navigationController?(nav, didShow: checkout, animated: false)
        navigator.pop(animated: false)
        nav.delegate?.navigationController?(nav, didShow: home, animated: false)    // back: a new view of home

        #expect(analytics.events.map { $0.parameters["screen_name"]?.description ?? "" } == ["home", "checkout", "home"])
        window.isHidden = true
    }
}
