//
//  FavoritesRepository.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Foundation

/// A saved event, safe to pass between threads and to the UI.
public struct FavoriteEvent: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let savedAt: Date

    public init(id: String, title: String, savedAt: Date) {
        self.id = id
        self.title = title
        self.savedAt = savedAt
    }
}

/// Favorites stored on the device (implemented with SwiftData in the Data layer).
///
///     let favorites = Container.shared.favoritesRepository()
///     let isFavorite = try await favorites.toggle(event)
///     let all = try await favorites.favorites()
public protocol FavoritesRepository: Sendable {
    func favorites() async throws -> [FavoriteEvent]
    func isFavorite(eventID: String) async throws -> Bool
    /// Adds or removes. Returns the new state (`true` = now a favorite).
    func toggle(_ event: Event) async throws -> Bool
    func removeAll() async throws
}

public extension Container {
    /// Registered by the composition root (`AppAssembly`) with the SwiftData implementation.
    var favoritesRepository: Dependency<any FavoritesRepository> {
        Dependency(self) { UnconfiguredFavoritesRepository() }.singleton
    }
}

/// Default until the app registers the real repository: fails safely, never crashes.
struct UnconfiguredFavoritesRepository: FavoritesRepository {
    func favorites() async throws -> [FavoriteEvent] { throw DomainError.notConfigured("FavoritesRepository") }
    func isFavorite(eventID: String) async throws -> Bool { throw DomainError.notConfigured("FavoritesRepository") }
    func toggle(_ event: Event) async throws -> Bool { throw DomainError.notConfigured("FavoritesRepository") }
    func removeAll() async throws { throw DomainError.notConfigured("FavoritesRepository") }
}
