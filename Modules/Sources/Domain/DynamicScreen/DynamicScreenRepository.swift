//
//  DynamicScreenRepository.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Core
import Foundation

/// A screen described by the backend (BFF), still as JSON: the presentation
/// layer decodes and renders it (ServerDrivenUI). Domain only moves it around.
public struct DynamicScreenPayload: Sendable, Equatable {
    public enum Source: Sendable, Equatable {
        /// Fresh from the BFF.
        case network
        /// Last good copy (the BFF failed).
        case cache
        /// Shipped in the app (first launch offline).
        case bundled
    }

    public let id: String
    public let json: Data
    public let source: Source

    public init(id: String, json: Data, source: Source) {
        self.id = id
        self.json = json
        self.source = source
    }
}

/// Where server-driven screens come from. Implemented in the Data layer.
public protocol DynamicScreenRepository: Sendable {
    /// The screen `id`, from the BFF, else the last good copy, else the bundled one.
    func screen(id: String) async throws -> DynamicScreenPayload
}

public enum DynamicScreenRepositoryError: Error, Equatable, LocalizedError {
    case unavailable(id: String)

    public var errorDescription: String? {
        "This page is not available right now."
    }
}

public extension Container {
    /// Registered by the composition root (`AppAssembly`) with the Data implementation.
    var dynamicScreenRepository: Dependency<any DynamicScreenRepository> {
        Dependency(self) { UnconfiguredDynamicScreenRepository() }.singleton
    }
}

/// Default until the app registers the real repository: fails safely, never crashes.
struct UnconfiguredDynamicScreenRepository: DynamicScreenRepository {
    func screen(id: String) async throws -> DynamicScreenPayload {
        throw DomainError.notConfigured("DynamicScreenRepository")
    }
}
