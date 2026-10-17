//
//  StorageKey.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation

/// Typed key: the value type travels with the key, so reads and writes
/// can't disagree and there are no string typos at call sites.
///
///     extension StorageKey where Value == String {
///         static let accessToken = StorageKey("auth.accessToken")
///     }
///     secureStore[.accessToken] = "abc"
///     let token = secureStore[.accessToken]   // String?
public struct StorageKey<Value: Codable & Sendable>: Sendable, Hashable {
    public let name: String

    /// `StorageKey<String>("auth.accessToken")` – use a namespaced, stable name.
    public init(_ name: String) {
        self.name = name
    }
}
