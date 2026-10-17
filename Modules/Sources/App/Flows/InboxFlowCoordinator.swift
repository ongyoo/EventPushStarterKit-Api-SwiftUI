//
//  InboxFlowCoordinator.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core


/// Inbox tab: notifications (UIKit + Storyboard) as root + shared destinations.
@MainActor
final class InboxFlowCoordinator: TabFlowCoordinator {
    override func start() {
        startNotifications(isRoot: true)
    }

    override func route(_ link: DeepLink) -> Bool {
        // The root already is the notification list.
        link.first == "notifications" ? link.dropFirst().isEmpty : super.route(link)
    }
}
