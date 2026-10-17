___FILEHEADER___

import DesignSystem
import Navigation
import UIKit

/// Assembles the scene. The only place that knows all VIPER parts.
///
/// Ownership: UIHostingController -> View -> Presenter -> Interactor.
/// Presenter -> Router is weak (the Coordinator owns the screen, not the opposite).
@MainActor
enum ___VARIABLE_sceneName___Builder {
    static func build(
        router: any ___VARIABLE_sceneName___Routing,
        interactor: any ___VARIABLE_sceneName___Interacting = ___VARIABLE_sceneName___Interactor()
    ) -> UIViewController {
        let presenter = ___VARIABLE_sceneName___Presenter(interactor: interactor, router: router)
        let view = ___VARIABLE_sceneName___View(presenter: presenter)
        return HostingController(rootView: view, title: "___VARIABLE_sceneName___")
    }
}
