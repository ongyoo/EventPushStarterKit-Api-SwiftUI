//
//  SecureStorageTests.swift
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

@Suite(.serialized)
struct SecureStorageTests {
    /// Package tests run without an app host: the simulator may refuse
    /// Keychain access (errSecMissingEntitlement). Covered by the app then.
    static let keychainAvailable: Bool = {
        let probe = KeychainStore(service: "tests.probe")
        probe.set(Data("1".utf8), for: "probe")
        defer { probe.removeAll() }
        return probe.data(for: "probe") != nil
    }()

    @Test(.enabled(if: keychainAvailable, "Keychain needs an app host"))
    func keychainRoundTripAndRemoveAll() {
        let store = KeychainStore(service: "tests.\(UUID().uuidString)")
        store[.token] = "abc"
        #expect(store[.token] == "abc")
        store[.token] = "def"
        #expect(store[.token] == "def")
        store.removeAll()
        #expect(store[.token] == nil)
    }

    // `.biometry` is not exercised here: reading it shows a Face ID prompt.
    @Test(arguments: [KeychainStore.Protection.whenUnlocked, .passcodeSet])
    func otherProtectionLevelsDoNotCrash(protection: KeychainStore.Protection) {
        let store = KeychainStore(service: "tests.\(UUID().uuidString)", protection: protection, accessGroup: nil)
        store[.token] = "abc"
        _ = store[.token]
        store.remove(.token)
        store.removeAll()
    }

    @Test func encryptedStoreRoundTripAndHidesPlaintext() throws {
        let folder = "Tests-\(UUID().uuidString)"
        let store = EncryptedFileStore(folder: folder, keyStore: KeychainStore(service: "tests.\(UUID().uuidString)"))
        store[.token] = "very secret"
        #expect(store[.token] == "very secret")

        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(folder)
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        #expect(files.count == 1)
        let raw = try Data(contentsOf: files[0])
        #expect(String(data: raw, encoding: .utf8)?.contains("very secret") != true)

        store[.token] = nil
        #expect(store[.token] == nil)
        store[.token] = "again"
        store.removeAll()
        #expect(store[.token] == nil)
    }

    @Test func userDefaultsStoreWithSuite() {
        let suite = "tests.\(UUID().uuidString)"
        let store = UserDefaultsStore(suiteName: suite)
        store[.token] = "abc"
        #expect(store[.token] == "abc")
        store.removeAll()
        #expect(store[.token] == nil)

        let standard = UserDefaultsStore()
        standard.set(Data("x".utf8), for: "tests.standard")
        #expect(standard.data(for: "tests.standard") == Data("x".utf8))
        standard.set(nil, for: "tests.standard")
    }

    @Test func bootstrapWipesOnlyOnFirstLaunch() throws {
        let defaults = try #require(UserDefaults(suiteName: "tests.\(UUID().uuidString)"))
        let store = InMemoryStore()
        store[.token] = "left over from previous install"

        SecureStorageBootstrap.run(preferences: defaults, storesToWipe: [store])
        #expect(store[.token] == nil)

        store[.token] = "new"
        SecureStorageBootstrap.run(preferences: defaults, storesToWipe: [store])
        #expect(store[.token] == "new")
    }

    @Test func defaultStoresResolve() {
        let container = Container()
        #expect(container.secureStore() is KeychainStore)
        #expect(container.encryptedStore() is EncryptedFileStore)
        #expect(container.preferences() is UserDefaultsStore)
    }
}
