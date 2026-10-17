//
//  DataAssembly.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Core
import DataSources
import Domain

/// Plugs the Data implementations into the Domain contracts.
/// Called once by the composition root (`AppAssembly.configure()`).
///
///     DataAssembly.register()          // app launch
///     container.eventRepository()      // -> RemoteEventRepository
public enum DataAssembly {
    /// - Parameter dynamicScreenSchemaVersion: highest server-driven UI schema
    ///   the app renders (`DynamicScreenDecoder.supportedSchemaVersion`).
    public static func register(in container: Container = .shared, dynamicScreenSchemaVersion: Int = 1) {
        container.dynamicScreenRepository.register {
            RemoteDynamicScreenRepository(
                api: container.apiClient(),
                cache: container.preferences(),
                schemaVersion: dynamicScreenSchemaVersion,
                language: { await MainActor.run { LocalizationManager.shared.current.code } }
            )
        }
        container.eventRepository.register {
            RemoteEventRepository(api: container.apiClient())
        }
        container.favoritesRepository.register {
            SwiftDataFavoritesRepository(modelContainer: container.database().container)
        }
    }
}
