//
//  Container.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation

/// Tiny dependency-injection container (no third-party library).
///
/// Declare a dependency once, with its default implementation:
///
///     public extension Container {
///         var apiClient: Dependency<any APIClient> {
///             Dependency(self) { URLSessionAPIClient() }.singleton
///         }
///     }
///
/// Resolve it:
///
///     let client = Container.shared.apiClient()
///
/// Replace it (tests, previews, another environment):
///
///     Container.shared.apiClient.register { MockAPIClient() }
///     Container.shared.reset()   // back to defaults
///
/// Every dependency always has a default, so a missing registration
/// is impossible: the compiler checks it, not a runtime crash.
public final class Container: @unchecked Sendable {
    /// The app-wide container. Tests can create their own: `let container = Container()`.
    public static let shared = Container()

    private let lock = NSRecursiveLock()
    private var overrides: [String: any Sendable] = [:]
    private var singletons: [String: Any] = [:]

    /// Empty container with only the declared defaults.
    public init() {}

    /// Removes every override and cached singleton.
    public func reset() {
        lock.withLock {
            overrides.removeAll()
            singletons.removeAll()
        }
    }

    fileprivate func resolve<T>(_ dependency: Dependency<T>) -> T {
        lock.withLock {
            let factory = (overrides[dependency.key] as? @Sendable () -> T) ?? dependency.factory

            guard dependency.scope == .singleton else { return factory() }
            if let cached = singletons[dependency.key] as? T { return cached }
            let instance = factory()
            singletons[dependency.key] = instance
            return instance
        }
    }

    fileprivate func register<T>(_ key: String, factory: @escaping @Sendable () -> T) {
        lock.withLock {
            overrides[key] = factory
            singletons[key] = nil
        }
    }
}

/// A declared dependency. Created by a `Container` extension property.
public struct Dependency<T>: Sendable {
    /// Lifetime of a resolved instance.
    public enum Scope: Sendable {
        /// New instance on every resolve (default).
        case unique
        /// One shared instance for the container's lifetime.
        case singleton
    }

    fileprivate let key: String
    fileprivate let factory: @Sendable () -> T
    fileprivate let scope: Scope
    private let container: Container

    /// `name` defaults to the calling property's name, which makes it the key.
    public init(_ container: Container, name: String = #function, factory: @escaping @Sendable () -> T) {
        self.init(container: container, key: "\(String(reflecting: T.self)).\(name)", scope: .unique, factory: factory)
    }

    private init(container: Container, key: String, scope: Scope, factory: @escaping @Sendable () -> T) {
        self.container = container
        self.key = key
        self.scope = scope
        self.factory = factory
    }

    /// Cache the instance (use for stateless services, clients, stores).
    public var singleton: Dependency<T> {
        Dependency(container: container, key: key, scope: .singleton, factory: factory)
    }

    public func callAsFunction() -> T {
        container.resolve(self)
    }

    /// Replace the default implementation.
    public func register(_ factory: @escaping @Sendable () -> T) {
        container.register(key, factory: factory)
    }
}
