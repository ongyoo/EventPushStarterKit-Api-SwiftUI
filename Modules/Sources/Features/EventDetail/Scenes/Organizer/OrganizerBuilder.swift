//
//  OrganizerBuilder.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import DesignSystem
import Domain
import Navigation
import UIKit

@MainActor
enum OrganizerBuilder {
    static func build(
        eventID: String,
        router: any OrganizerRouting,
        interactor: (any OrganizerInteracting)? = nil
    ) -> UIViewController {
        let presenter = OrganizerPresenter(
            interactor: interactor ?? OrganizerInteractor(eventID: eventID),
            router: router
        )
        return HostingController(rootView: OrganizerView(presenter: presenter), title: L10n.Event.organizerTitle)
    }
}
