//
//  SettingsBuilder.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import DesignSystem
import Navigation
import UIKit

@MainActor
enum SettingsBuilder {
    static func build(
        router: any SettingsRouting,
        interactor: any SettingsInteracting
    ) -> UIViewController {
        let presenter = SettingsPresenter(interactor: interactor, router: router)
        return HostingController(rootView: SettingsView(presenter: presenter), title: L10n.tr("settings.title"), largeTitle: true)
    }
}
