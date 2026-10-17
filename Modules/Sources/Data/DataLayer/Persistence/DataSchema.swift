//
//  DataSchema.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import DataSources
import Foundation
import SwiftData

/// Every SwiftData model of the app, in one place. Add new `@Model` types here.
public enum DataSchema {
    /// Passed to `Database(models:)`. Changing a model? Add a `VersionedSchema` + migration plan.
    public static let models: [any PersistentModel.Type] = [
        FavoriteEventRecord.self,
    ]
}

public extension Container {
    /// The app database. Tests: `Container.shared.database.register { Database(models: DataSchema.models, inMemory: true) }`.
    var database: Dependency<Database> {
        Dependency(self) { Database(models: DataSchema.models) }.singleton
    }
}
