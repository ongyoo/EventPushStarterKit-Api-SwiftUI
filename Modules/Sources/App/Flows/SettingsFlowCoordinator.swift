//
//  SettingsFlowCoordinator.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Features


/// Settings tab: Settings screen as root + shared destinations.
@MainActor
final class SettingsFlowCoordinator: TabFlowCoordinator {
    override func start() {
        startChild(SettingsCoordinator(navigator: navigator, isRoot: true) { SettingsInteractor() })
    }
}
