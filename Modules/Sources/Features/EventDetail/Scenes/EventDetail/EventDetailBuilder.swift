//
//  EventDetailBuilder.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import DesignSystem
import Domain
import Navigation
import UIKit

@MainActor
enum EventDetailBuilder {
    static func build(
        eventID: String,
        router: any EventDetailRouting,
        interactor: (any EventDetailInteracting)? = nil
    ) -> UIViewController {
        let presenter = EventDetailPresenter(
            interactor: interactor ?? EventDetailInteractor(eventID: eventID),
            router: router
        )
        return HostingController(rootView: EventDetailView(presenter: presenter), title: L10n.Event.title)
    }
}
