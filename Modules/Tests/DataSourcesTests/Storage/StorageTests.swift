//
//  StorageTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
@testable import DataSources
import Foundation
import Testing

private extension StorageKey where Value == String {
    static let token = StorageKey("test.token")
}

private struct Profile: Codable, Sendable, Equatable {
    let name: String
}

private extension StorageKey where Value == Profile {
    static let profile = StorageKey("test.profile")
}

struct StorageTests {
    @Test func typedKeysRoundTrip() {
        let store = InMemoryStore()
        store[.token] = "abc"
        store[.profile] = Profile(name: "Ann")

        #expect(store[.token] == "abc")
        #expect(store[.profile] == Profile(name: "Ann"))

        store[.token] = nil
        #expect(store[.token] == nil)
    }

    @Test func removeAllClearsStore() {
        let store = InMemoryStore()
        store[.token] = "abc"
        store.removeAll()
        #expect(store[.token] == nil)
    }

    @Test func databaseStoreLivesInApplicationSupport() {
        #expect(Database.storeURL(fileName: "x.store")?.lastPathComponent == "x.store")
        #expect(Database(models: [], inMemory: true).isPersistent == false)
    }
}
