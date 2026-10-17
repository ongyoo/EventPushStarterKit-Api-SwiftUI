//
//  RemoteDynamicScreenRepository.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Core
import DataSources
import Domain
import Foundation

/// BFF first; on failure the last good copy (kept in `cache`), then the copy
/// shipped in the app. A campaign screen still opens offline.
public final class RemoteDynamicScreenRepository: DynamicScreenRepository {
    private let api: any APIClient
    private let cache: any KeyValueStore
    private let schemaVersion: Int
    private let language: @Sendable () async -> String

    /// - Parameters:
    ///   - cache: where the last good JSON of each screen is kept (preferences / file store).
    ///   - schemaVersion: highest schema this build renders (sent to the BFF).
    public init(
        api: any APIClient,
        cache: any KeyValueStore,
        schemaVersion: Int,
        language: @escaping @Sendable () async -> String = { Locale.current.language.languageCode?.identifier ?? "en" }
    ) {
        self.api = api
        self.cache = cache
        self.schemaVersion = schemaVersion
        self.language = language
    }

    public func screen(id: String) async throws -> DynamicScreenPayload {
        let key = StorageKey<Data>("bff.screen.\(id)")
        do {
            let endpoint = DynamicScreenEndpoint.screen(id: id, schemaVersion: schemaVersion, language: await language())
            let json = try await api.data(endpoint)
            cache[key] = json
            return DynamicScreenPayload(id: id, json: json, source: .network)
        } catch {
            if let cached = cache[key] {
                return DynamicScreenPayload(id: id, json: cached, source: .cache)
            }
            if let bundled = DynamicScreenFixtures.json(for: id) {
                return DynamicScreenPayload(id: id, json: bundled, source: .bundled)
            }
            throw DynamicScreenRepositoryError.unavailable(id: id)
        }
    }
}

/// Screens shipped in the app: offline fallback, Mock API mode and tests.
public enum DynamicScreenFixtures {
    /// Ids of the bundled screens (`screen-<id>.json` in Resources/Fixtures).
    public static let ids = ["showcase", "songkran"]

    public static func json(for id: String) -> Data? {
        guard let url = Bundle.module.url(forResource: "screen-\(id)", withExtension: "json") else { return nil }
        return try? Data(contentsOf: url)
    }

    /// `[endpoint path: JSON]` for `MockAPIClient`.
    public static var responses: [String: Data] {
        Dictionary(uniqueKeysWithValues: ids.compactMap { id in
            json(for: id).map { (DynamicScreenEndpoint.screen(id: id, schemaVersion: 1, language: "en").path, $0) }
        })
    }
}
