//
//  NotificationBuilder.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import UIKit

/// Assembles the scene. The only place that knows all VIPER parts.
///
/// Ownership: ViewController -> Presenter -> Interactor (strong).
/// Presenter -> View and Presenter -> Router are weak: no retain cycles.
@MainActor
enum NotificationBuilder {
    static func build(
        router: any NotificationRouting,
        interactor: any NotificationInteracting = NotificationInteractor()
    ) -> UIViewController {
        let viewController = NotificationViewController.instantiate()
        let presenter = NotificationPresenter(interactor: interactor, router: router)
        presenter.view = viewController
        viewController.presenter = presenter
        return viewController
    }
}
