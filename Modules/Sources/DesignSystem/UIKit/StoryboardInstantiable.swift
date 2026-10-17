//
//  StoryboardInstantiable.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import UIKit

/// Load a view controller from a storyboard inside a Swift package.
///
/// Conventions (so no string typing is needed):
/// - Storyboard file name == class name without "ViewController"
///   (`NotificationListViewController` -> `NotificationList.storyboard`)
/// - Scene "Storyboard ID" == class name
/// - Scene "Module" == the package target name (e.g. `NotificationFeature`)
///
///     final class NotificationListViewController: UIViewController, StoryboardInstantiable {
///         static var bundle: Bundle { .module }
///     }
///     let vc = NotificationListViewController.instantiate()
@MainActor
public protocol StoryboardInstantiable: UIViewController {
    static var bundle: Bundle { get }
    static var storyboardName: String { get }
    static var storyboardID: String { get }
}

public extension StoryboardInstantiable {
    static var storyboardName: String {
        String(describing: self).replacingOccurrences(of: "ViewController", with: "")
    }

    static var storyboardID: String { String(describing: self) }

    /// Never crashes: a misconfigured storyboard stops the debugger in Debug
    /// and falls back to an empty controller in Release.
    static func instantiate() -> Self {
        let storyboard = UIStoryboard(name: storyboardName, bundle: bundle)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: storyboardID) as? Self else {
            assertionFailure("\(storyboardID) not found in \(storyboardName).storyboard. Check Storyboard ID and Module.")
            return Self(nibName: nil, bundle: nil)
        }
        return viewController
    }
}

/// Register / dequeue cells by type instead of string identifiers.
public protocol Reusable: AnyObject {
    static var reuseIdentifier: String { get }
}

public extension Reusable {
    static var reuseIdentifier: String { String(describing: self) }
}

extension UITableViewCell: Reusable {}
extension UICollectionViewCell: Reusable {}

public extension UITableView {
    func register<Cell: UITableViewCell>(_ type: Cell.Type) {
        register(type, forCellReuseIdentifier: type.reuseIdentifier)
    }

    func dequeue<Cell: UITableViewCell>(_ type: Cell.Type, for indexPath: IndexPath) -> Cell {
        guard let cell = dequeueReusableCell(withIdentifier: type.reuseIdentifier, for: indexPath) as? Cell else {
            assertionFailure("Cell \(type.reuseIdentifier) is not registered")
            return Cell(style: .default, reuseIdentifier: type.reuseIdentifier)
        }
        return cell
    }
}

public extension UICollectionView {
    func register<Cell: UICollectionViewCell>(_ type: Cell.Type) {
        register(type, forCellWithReuseIdentifier: type.reuseIdentifier)
    }

    func dequeue<Cell: UICollectionViewCell>(_ type: Cell.Type, for indexPath: IndexPath) -> Cell {
        guard let cell = dequeueReusableCell(withReuseIdentifier: type.reuseIdentifier, for: indexPath) as? Cell else {
            assertionFailure("Cell \(type.reuseIdentifier) is not registered")
            return Cell(frame: .zero)
        }
        return cell
    }
}
