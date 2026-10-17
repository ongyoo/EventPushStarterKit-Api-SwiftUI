//
//  EventListBuilder.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import DesignSystem
import Domain
import Navigation
import UIKit

@MainActor
enum EventListBuilder {
    static func build(
        category: EventCategory,
        router: any EventListRouting,
        interactor: any EventListInteracting = EventListInteractor()
    ) -> UIViewController {
        let presenter = EventListPresenter(category: category, interactor: interactor, router: router)
        return HostingController(rootView: EventListView(presenter: presenter), title: L10n.Events.allTitle)
    }
}
