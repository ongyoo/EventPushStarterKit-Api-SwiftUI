//
//  DataAssembly.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Core
import DataSources
import Domain

// Data layer: implements the Domain repository protocols.
//
//   DataLayer/<Area>/Remote/   DTOs + mapping to entities, endpoints, API repositories
//   DataLayer/<Area>/Local/    SwiftData @Model records + @ModelActor repositories
//   DataLayer/Persistence/     DataSchema (every @Model type)

/// Plugs the Data implementations into the Domain contracts.
/// Called once by the composition root (`AppAssembly.configure()`).
public enum DataAssembly {
    public static func register(in container: Container = .shared) {
        // container.profileRepository.register { RemoteProfileRepository(api: container.apiClient()) }
    }
}
