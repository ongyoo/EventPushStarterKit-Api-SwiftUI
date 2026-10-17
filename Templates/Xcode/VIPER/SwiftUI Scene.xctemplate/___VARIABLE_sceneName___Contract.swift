___FILEHEADER___

import Foundation

// MARK: - Entity (screen model)

/// What this screen displays. Map domain entities into it in the Interactor
/// if the screen needs a different shape; otherwise use the domain entity.
struct ___VARIABLE_sceneName___Item: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
}

// MARK: - Router (implemented by the feature Coordinator)

/// Navigation requests from this screen. The Coordinator decides how.
@MainActor
protocol ___VARIABLE_sceneName___Routing: AnyObject {
    func showItem(id: String)  // rename to the real destination, e.g. showDetail(id:)
}

// MARK: - Interactor (business logic, no UI)

protocol ___VARIABLE_sceneName___Interacting: Sendable {
    func fetchItems() async throws -> [___VARIABLE_sceneName___Item]
}
