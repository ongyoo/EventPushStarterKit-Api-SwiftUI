//
//  AppDelegate.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import App
import UIKit

/// Keep this file tiny: launch setup lives in `AppAssembly`,
/// navigation in `AppCoordinator` (both in the App module: Modules/Sources/App).
@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Registers background tasks too: must happen before this method returns.
        AppAssembly.configure()
        #if FEATURE_SILENT_PUSH
        AppPush.register()
        #endif
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    #if FEATURE_SILENT_PUSH
    // MARK: - Remote / silent push (FEATURE_SILENT_PUSH = YES)

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        AppPush.didRegister(deviceToken: deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        AppPush.didFailToRegister(error)
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any]
    ) async -> UIBackgroundFetchResult {
        await AppPush.didReceive(userInfo)
    }
    #endif
}
