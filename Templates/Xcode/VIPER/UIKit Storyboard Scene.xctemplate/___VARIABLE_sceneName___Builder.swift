___FILEHEADER___

import UIKit

/// Assembles the scene. The only place that knows all VIPER parts.
///
/// Ownership: ViewController -> Presenter -> Interactor (strong).
/// Presenter -> View and Presenter -> Router are weak: no retain cycles.
@MainActor
enum ___VARIABLE_sceneName___Builder {
    static func build(
        router: any ___VARIABLE_sceneName___Routing,
        interactor: any ___VARIABLE_sceneName___Interacting = ___VARIABLE_sceneName___Interactor()
    ) -> UIViewController {
        let viewController = ___VARIABLE_sceneName___ViewController.instantiate()
        let presenter = ___VARIABLE_sceneName___Presenter(interactor: interactor, router: router)
        presenter.view = viewController
        viewController.presenter = presenter
        return viewController
    }
}
