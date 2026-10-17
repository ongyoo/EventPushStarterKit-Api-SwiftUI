//
//  TestSupport.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Domain
@testable import Features
import Foundation
import UIKit

// Shared test doubles for every feature test (one module = one namespace,
// so shared helpers live here instead of being redeclared per file).

struct StubError: LocalizedError {
    var errorDescription: String? { "Stub failure" }
}

struct RepositoryStub: EventRepository {
    var events: [Event] = Event.samples
    var error: (any Error)?

    func events() async throws -> [Event] {
        if let error { throw error }
        return events
    }

    func event(id: String) async throws -> Event {
        if let error { throw error }
        guard let event = events.first(where: { $0.id == id }) else { throw EventRepositoryError.notFound }
        return event
    }
}

/// Puts a view controller in a real window so SwiftUI bodies are evaluated.
@MainActor
func render(_ viewController: UIViewController) {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.rootViewController = viewController
    window.makeKeyAndVisible()
    viewController.view.layoutIfNeeded()
}

/// In-memory favorites for feature tests.
actor FavoritesStub: FavoritesRepository {
    private var ids: Set<String> = []
    private let failing: Bool

    init(failing: Bool = false) {
        self.failing = failing
    }

    func favorites() async throws -> [FavoriteEvent] { [] }
    func isFavorite(eventID: String) async throws -> Bool { ids.contains(eventID) }

    func toggle(_ event: Event) async throws -> Bool {
        if failing { throw StubError() }
        if ids.remove(event.id) == nil { ids.insert(event.id); return true }
        return false
    }

    func removeAll() async throws { ids.removeAll() }
}
