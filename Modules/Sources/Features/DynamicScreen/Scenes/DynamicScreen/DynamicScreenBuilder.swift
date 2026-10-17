//
//  DynamicScreenBuilder.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Navigation
import UIKit

@MainActor
enum DynamicScreenBuilder {
    static func build(
        screenID: String,
        router: any DynamicScreenRouting,
        showsClose: Bool = false,
        interactor: any DynamicScreenInteracting = DynamicScreenInteractor()
    ) -> UIViewController {
        let presenter = DynamicScreenPresenter(screenID: screenID, interactor: interactor, router: router)
        return HostingController(
            rootView: DynamicScreenScreen(presenter: presenter, showsClose: showsClose),
            screenName: "dynamic_\(screenID)"
        )
    }
}
