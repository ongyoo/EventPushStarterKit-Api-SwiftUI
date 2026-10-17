//
//  SwiftDataFavoritesRepository.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import DataSources
import Domain
import Foundation
import SwiftData

/// `@ModelActor` = its own background `ModelContext`: database work never
/// blocks the UI, and only Sendable values leave the actor.
@ModelActor
public actor SwiftDataFavoritesRepository: FavoritesRepository {
    public func favorites() throws -> [FavoriteEvent] {
        let descriptor = FetchDescriptor<FavoriteEventRecord>(sortBy: [SortDescriptor(\.savedAt, order: .reverse)])
        return try modelContext.fetch(descriptor).map {
            FavoriteEvent(id: $0.eventID, title: $0.title, savedAt: $0.savedAt)
        }
    }

    public func isFavorite(eventID: String) throws -> Bool {
        try record(eventID) != nil
    }

    public func toggle(_ event: Event) throws -> Bool {
        if let existing = try record(event.id) {
            modelContext.delete(existing)
            try modelContext.save()
            return false
        }
        modelContext.insert(FavoriteEventRecord(eventID: event.id, title: event.title))
        try modelContext.save()
        return true
    }

    public func removeAll() throws {
        try modelContext.delete(model: FavoriteEventRecord.self)
        try modelContext.save()
    }

    private func record(_ eventID: String) throws -> FavoriteEventRecord? {
        var descriptor = FetchDescriptor<FavoriteEventRecord>(predicate: #Predicate { $0.eventID == eventID })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
