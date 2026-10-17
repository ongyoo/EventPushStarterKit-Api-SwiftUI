//
//  HomeFlowCoordinator.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Features
import Navigation

/// Home tab: Home screen as root.
@MainActor
final class HomeFlowCoordinator: TabFlowCoordinator {
    override func start() {
        let home = HomeCoordinator(navigator: navigator, isRoot: true)
        home.onOutput = { output in
            switch output {
            case .itemSelected:
                // Start another feature here, e.g. self?.showDetail(id: id)
                break
            }
        }
        startChild(home)
    }
}
