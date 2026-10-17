___FILEHEADER___

import Core
import Navigation
import UIKit

/// Entry point of the ___VARIABLE_featureName___ feature.
/// Other features never call its screens directly: they go through the
/// parent flow (App layer), which starts this coordinator. The coordinator
/// is the feature's only public API.
///
/// Deep links (relative to this feature, the parent strips its own prefix):
///
/// | Path      | Screen                |
/// |-----------|-----------------------|
/// | (empty)   | ___VARIABLE_featureName___ (first screen) |
public final class ___VARIABLE_featureName___Coordinator: Coordinator {
    /// Things this feature can't decide alone (e.g. open another feature).
    /// The parent flow handles them, so features never import each other.
    public enum Output: Equatable {
        case itemSelected(id: String)
    }

    /// Set by the parent with `[weak self]`.
    public var onOutput: ((Output) -> Void)?

    private let isRoot: Bool

    /// - Parameter isRoot: `true` when this feature is a tab root.
    public init(navigator: Navigator, isRoot: Bool = false) {
        self.isRoot = isRoot
        super.init(navigator: navigator)
    }

    override public func start() {
        showFirstScreen(___VARIABLE_featureName___Builder.build(router: self), asRoot: isRoot)
    }

    @discardableResult
    override public func handle(_ link: DeepLink) -> Bool {
        // Empty = first screen, already shown by start().
        // Add cases for deeper screens: case "settings": showSettings()
        link.isEmpty
    }
}

// MARK: - Routing

extension ___VARIABLE_featureName___Coordinator: ___VARIABLE_featureName___Routing {
    func showItem(id: String) {
        onOutput?(.itemSelected(id: id))
    }
}
