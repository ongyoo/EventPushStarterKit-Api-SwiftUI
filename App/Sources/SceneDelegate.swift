//
//  SceneDelegate.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import App
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var appCoordinator: AppCoordinator?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        let coordinator = AppCoordinator(window: window)
        self.window = window
        self.appCoordinator = coordinator

        // Cold launch from a link: queue it, AppCoordinator handles it after start().
        connectionOptions.urlContexts.forEach { coordinator.open($0.url) }
        connectionOptions.userActivities.compactMap(\.webpageURL).forEach { coordinator.open($0) }

        #if DEBUG
        // QA shortcut: launch with `-DeepLink eventpush://events/1/organizer`
        // (Xcode scheme arguments or `xcrun simctl launch <device> <bundle id> -DeepLink <url>`).
        if let link = UserDefaults.standard.string(forKey: "DeepLink"), let url = URL(string: link) {
            coordinator.open(url)
        }
        #endif

        coordinator.start()
    }

    // Custom scheme: eventpush://events/42
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        URLContexts.forEach { appCoordinator?.open($0.url) }
    }

    // Universal link: https://eventpush.app/events/42
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard let url = userActivity.webpageURL else { return }
        appCoordinator?.open(url)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        appCoordinator?.sceneWillResignActive()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        appCoordinator?.sceneDidBecomeActive()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        appCoordinator?.sceneDidEnterBackground()
    }
}
