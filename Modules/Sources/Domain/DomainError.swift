//
//  DomainError.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation

/// Errors any domain contract can throw, whatever the feature.
public enum DomainError: Error, LocalizedError, Equatable {
    /// The composition root did not register an implementation (a setup bug, caught by `AppAssemblyTests`).
    case notConfigured(String)

    public var errorDescription: String? {
        switch self {
        case let .notConfigured(name): "\(name) is not configured."
        }
    }
}
