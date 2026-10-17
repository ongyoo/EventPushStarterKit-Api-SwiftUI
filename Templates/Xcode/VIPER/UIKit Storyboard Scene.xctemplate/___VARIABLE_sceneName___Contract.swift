___FILEHEADER___

import Core
import Foundation

// MARK: - Entity (screen model)

struct ___VARIABLE_sceneName___Item: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
}

// MARK: - View (implemented by the ViewController)

/// What the presenter can ask the view to show.
@MainActor
protocol ___VARIABLE_sceneName___ViewInput: AnyObject {
    func render(_ state: Loadable<[___VARIABLE_sceneName___Item]>)
}

// MARK: - Presenter (called by the ViewController)

@MainActor
protocol ___VARIABLE_sceneName___Presenting: AnyObject {
    func viewDidLoad()
    func didPullToRefresh()
    func didSelectItem(at index: Int)
}

// MARK: - Router (implemented by the feature Coordinator)

@MainActor
protocol ___VARIABLE_sceneName___Routing: AnyObject {
    func showItem(id: String)  // rename to the real destination, e.g. showDetail(id:)
}

// MARK: - Interactor (business logic, no UI)

protocol ___VARIABLE_sceneName___Interacting: Sendable {
    func fetchItems() async throws -> [___VARIABLE_sceneName___Item]
}
