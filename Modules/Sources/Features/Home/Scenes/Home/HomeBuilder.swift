//
//  HomeBuilder.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import DesignSystem
import Navigation
import UIKit

@MainActor
enum HomeBuilder {
    static func build(
        router: any HomeRouting,
        interactor: any HomeInteracting = HomeInteractor()
    ) -> UIViewController {
        let presenter = HomePresenter(interactor: interactor, router: router)
        // Home draws its own header: no navigation bar here. Screens pushed on
        // top (event detail...) get the bar and their back button automatically.
        return HostingController(rootView: HomeView(presenter: presenter), title: L10n.Home.title, hidesNavigationBar: true)
    }
}
