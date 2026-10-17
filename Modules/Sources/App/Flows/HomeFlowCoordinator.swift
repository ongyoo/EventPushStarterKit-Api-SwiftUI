//
//  HomeFlowCoordinator.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Features



/// Home tab: Home screen as root + shared destinations.
@MainActor
final class HomeFlowCoordinator: TabFlowCoordinator {
    override func start() {
        let home = HomeCoordinator(navigator: navigator, isRoot: true)
        home.onOutput = { [weak self] output in
            switch output {
            case let .featuredEventSelected(id): self?.showFeaturedEventDetail(id: id)
            case let .eventSelected(id): self?.showEventDetail(id: id)
            case let .seeAllEvents(category): self?.showEventList(category: category)
            case .notificationsSelected: self?.presentNotifications()
            }
        }
        startChild(home)
    }
}
