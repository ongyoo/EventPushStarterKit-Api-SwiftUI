//
//  Loadable.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation

/// Standard async screen state. Use it instead of separate
/// `isLoading` / `errorMessage` / `data` flags that can get out of sync.
public enum Loadable<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(String)

    /// The loaded value, or `nil` in any other state.
    public var value: Value? {
        if case let .loaded(value) = self { return value }
        return nil
    }

    /// `true` only in `.loading`.
    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    /// The message of `.failed`, else `nil`.
    public var errorMessage: String? {
        if case let .failed(message) = self { return message }
        return nil
    }
}

extension Loadable: Equatable where Value: Equatable {}
extension Loadable: Sendable where Value: Sendable {}
