//
//  KeyValueStore.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation

/// Common storage API. Pick the implementation by sensitivity:
///
/// | Store                | Use for                                      |
/// |----------------------|----------------------------------------------|
/// | `KeychainStore`      | tokens, passwords, PIN, keys (secrets)       |
/// | `EncryptedFileStore` | larger sensitive data (profile, PII, docs)   |
/// | `UserDefaultsStore`  | non-sensitive preferences and flags          |
/// | `InMemoryStore`      | tests, previews, session-only values         |
///
/// See `docs/DATA_STORAGE.md`.
public protocol KeyValueStore: Sendable {
    func data(for key: String) -> Data?
    func set(_ data: Data?, for key: String)
    func removeAll()
}

public extension KeyValueStore {
    /// Typed read/write. Assign `nil` to delete.
    subscript<Value>(key: StorageKey<Value>) -> Value? {
        get {
            guard let data = data(for: key.name) else { return nil }
            return try? JSONDecoder().decode(Value.self, from: data)
        }
        nonmutating set {
            set(newValue.flatMap { try? JSONEncoder().encode($0) }, for: key.name)
        }
    }

    func remove<Value>(_ key: StorageKey<Value>) {
        set(nil, for: key.name)
    }
}

/// For unit tests and SwiftUI previews.
public final class InMemoryStore: KeyValueStore, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: Data] = [:]

    /// Empty store: `Container.shared.secureStore.register { InMemoryStore() }` in tests.
    public init() {}

    public func data(for key: String) -> Data? {
        lock.withLock { storage[key] }
    }

    public func set(_ data: Data?, for key: String) {
        lock.withLock { storage[key] = data }
    }

    public func removeAll() {
        lock.withLock { storage.removeAll() }
    }
}
