___FILEHEADER___

import Core
import Foundation

/// Business logic for the scene. Talks to repositories / services,
/// never to UIKit or SwiftUI. Dependencies come from `Container` by default
/// so tests can pass mocks through `init`.
final class ___VARIABLE_sceneName___Interactor: ___VARIABLE_sceneName___Interacting {
    init() {}

    func fetchItems() async throws -> [___VARIABLE_sceneName___Item] {
        // TODO: call a repository, e.g. `try await repository.items()`
        [
            ___VARIABLE_sceneName___Item(id: "1", title: "First item"),
            ___VARIABLE_sceneName___Item(id: "2", title: "Second item"),
        ]
    }
}
