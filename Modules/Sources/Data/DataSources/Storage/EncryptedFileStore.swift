//
//  EncryptedFileStore.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import CryptoKit
import Foundation

/// Encrypted on-disk storage for larger sensitive data
/// (user profile, cached PII, documents, offline data).
///
/// Two layers of protection:
/// 1. AES-GCM 256 encryption; the key lives in the Keychain (this device only).
/// 2. iOS Data Protection on the file + excluded from iCloud/iTunes backup.
///
/// Data written here cannot be read on another device or from a backup.
public final class EncryptedFileStore: KeyValueStore, @unchecked Sendable {
    private let directory: URL
    private let keyStore: KeychainStore
    private let lock = NSLock()
    private var cachedKey: SymmetricKey?

    /// `EncryptedFileStore(keyStore: KeychainStore(service: "com.app.keys"))`
    /// The AES key is created on first use and kept in `keyStore`.
    public init(folder: String = "SecureStore", keyStore: KeychainStore) {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.directory = base.appendingPathComponent(folder, isDirectory: true)
        self.keyStore = keyStore
        prepareDirectory()
    }

    public func data(for key: String) -> Data? {
        lock.withLock {
            guard let encrypted = try? Data(contentsOf: fileURL(for: key)),
                  let box = try? AES.GCM.SealedBox(combined: encrypted),
                  let plain = try? AES.GCM.open(box, using: encryptionKey()) else { return nil }
            return plain
        }
    }

    public func set(_ data: Data?, for key: String) {
        lock.withLock {
            let url = fileURL(for: key)
            guard let data else {
                try? FileManager.default.removeItem(at: url)
                return
            }
            do {
                let sealed = try AES.GCM.seal(data, using: encryptionKey())
                guard let combined = sealed.combined else { return }
                try combined.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            } catch {
                Log.app.error("Encrypted write failed: \(error.localizedDescription)")
            }
        }
    }

    public func removeAll() {
        lock.withLock {
            try? FileManager.default.removeItem(at: directory)
            prepareDirectory()
        }
    }

    // MARK: - Private

    private func fileURL(for key: String) -> URL {
        // Hash the key so file names don't reveal what is stored.
        let name = SHA256.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent(name)
    }

    private func encryptionKey() -> SymmetricKey {
        if let cachedKey { return cachedKey }
        let keyName = "encrypted-file-store.key"
        let key: SymmetricKey
        if let stored = keyStore.data(for: keyName) {
            key = SymmetricKey(data: stored)
        } else {
            key = SymmetricKey(size: .bits256)
            keyStore.set(key.withUnsafeBytes { Data($0) }, for: keyName)
        }
        cachedKey = key
        return key
    }

    private func prepareDirectory() {
        var url = directory
        try? FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
        )
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)
    }
}
