//
//  Database.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Foundation
import SwiftData

/// One SwiftData store for the app: structured data, queries, offline-first.
///
///     let database = Database(models: [FavoriteEventRecord.self])
///     // Background work (recommended): a @ModelActor repository
///     let repository = MyRepository(modelContainer: database.container)
///     // SwiftUI views: .modelContainer(database.container) + @Query
///
/// Safety:
/// - the store file is protected by iOS Data Protection and excluded from backup;
/// - if the store can't be opened (corrupt file, failed migration) it falls back
///   to an in-memory store and logs a fault, instead of crashing at launch.
public final class Database: Sendable {
    /// Pass to `@ModelActor` repositories or `.modelContainer(_:)` in SwiftUI.
    public let container: ModelContainer
    /// `false` when running on the in-memory fallback (data won't persist).
    public let isPersistent: Bool

    /// - Parameters:
    ///   - models: every `@Model` type of the app (see `DataSchema.models` in DataLayer).
    ///   - inMemory: `true` for tests and previews.
    ///   - migrationPlan: your `SchemaMigrationPlan` once you ship schema changes.
    public init(
        models: [any PersistentModel.Type],
        inMemory: Bool = false,
        fileName: String = "App.store",
        migrationPlan: (any SchemaMigrationPlan.Type)? = nil
    ) {
        let schema = Schema(models)
        if !inMemory, let url = Self.storeURL(fileName: fileName),
           let container = try? ModelContainer(for: schema, migrationPlan: migrationPlan, configurations: ModelConfiguration(schema: schema, url: url)) {
            self.container = container
            self.isPersistent = true
            return
        }
        if !inMemory {
            Log.app.fault("Database could not be opened: using an in-memory store")
        }
        let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        // In-memory creation only fails for an invalid schema (a programming error).
        self.container = (try? ModelContainer(for: schema, configurations: memory))
            ?? Self.emptyContainer()
        self.isPersistent = false
    }

    /// Application Support/Database/<fileName>, protected and not backed up.
    static func storeURL(fileName: String) -> URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        var directory = base.appendingPathComponent("Database", isDirectory: true)
        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
            )
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try directory.setResourceValues(values)
        } catch {
            return nil
        }
        return directory.appendingPathComponent(fileName)
    }

    /// Last resort for an invalid schema (a programming error caught in Debug).
    /// An empty in-memory schema always loads.
    private static func emptyContainer() -> ModelContainer {
        assertionFailure("Invalid SwiftData schema")
        return try! ModelContainer(for: Schema([]), configurations: ModelConfiguration(isStoredInMemoryOnly: true)) // lint:allow – empty in-memory schema cannot fail
    }
}
