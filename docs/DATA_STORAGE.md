# Data storage: what goes where

Pick the store by **how bad it would be if someone read the data**.

| Data | Store | API | Why |
|---|---|---|---|
| Access / refresh token, password, PIN, API secret, encryption key | **Keychain** | `Container.shared.secureStore()` | Hardware-encrypted, never in backups (`ThisDeviceOnly`) |
| Secret that needs Face ID on every read | **Keychain + biometry** | `KeychainStore(service:protection: .biometry)` | iOS enforces it, can't be bypassed |
| Profile, PII, documents, sensitive offline data | **Encrypted file** | `Container.shared.encryptedStore()` | AES-GCM (key in Keychain) + Data Protection + excluded from backup |
| Settings, flags, "onboarding seen", last tab | **UserDefaults** | `Container.shared.preferences()` | Plain plist: fast, NOT secret |
| Images | **Kingfisher cache** | automatic via `RemoteImage` | Memory + disk, size limits in `ImageCache.configure` |
| API response cache | **Memory** (repository) or URLCache | e.g. `EventCache` actor | Cheap, cleared on relaunch |
| Values for the current session only | **Memory** | properties / `InMemoryStore` | Gone when the app quits |
| Structured data you query: favorites, history, drafts, offline cache | **SwiftData** | `Container.shared.database()` + a `@ModelActor` repository | Queries, relationships, migrations; protected file, not backed up |

**Never** put in UserDefaults, logs, Info.plist, analytics or crash reports:
tokens, passwords, card numbers, CVV, national ID, health data.

## SwiftData

`Database` (DataSources) creates the `ModelContainer`; `DataSchema.models`
(DataLayer) lists every `@Model`. The example is **Favorites** (heart on the event screen).

```
Domain/Event/Repositories/FavoritesRepository.swift          protocol + FavoriteEvent (Sendable struct)
Data/DataLayer/Event/Local/FavoriteEventRecord.swift              @Model – stays inside DataLayer
Data/DataLayer/Event/Local/SwiftDataFavoritesRepository.swift     @ModelActor implementation
Data/DataLayer/Persistence/DataSchema.swift                       models list + Container.database
Data/DataLayer/DataAssembly.swift                                 plugs it into Container.favoritesRepository
Data/DataSources/Database/Database.swift                          the ModelContainer (data source)
```

Rules:

- Features never see `@Model` classes: repositories return `Sendable` structs
  (`FavoriteEvent`). `@Model` objects are not thread-safe.
- Write through a `@ModelActor` repository (background context, never blocks UI).
- SwiftUI-only screens may read with `@Query` after `.modelContainer(database.container)`.
- Tests: `Database(models: DataSchema.models, inMemory: true)`.
- If the store can't open (corrupt file, failed migration) `Database` falls back
  to memory and logs a fault instead of crashing; `isPersistent` tells you.

Add a model:

```swift
@Model public final class DraftRecord { @Attribute(.unique) var id: String; var text: String; ... }
// 1. DataSchema.models += [DraftRecord.self]
// 2. DraftRepository protocol + @ModelActor SwiftDataDraftRepository
// 3. Container.draftRepository dependency
```

Change a shipped model: define `VersionedSchema`s and a `SchemaMigrationPlan`,
then pass it: `Database(models: DataSchema.models, migrationPlan: AppMigrationPlan.self)`.

## One API for all stores

Every store implements `KeyValueStore` with typed keys:

```swift
extension StorageKey where Value == String {
    static let accessToken = StorageKey("auth.accessToken")
}
extension StorageKey where Value == UserProfile {      // any Codable
    static let profile = StorageKey("user.profile")
}

let secure = Container.shared.secureStore()
secure[.accessToken] = token          // write
let token = secure[.accessToken]      // read (String?)
secure[.accessToken] = nil            // delete

Container.shared.encryptedStore()[.profile] = profile
Container.shared.preferences().removeAll()
```

Swap any store in tests: `Container.shared.secureStore.register { InMemoryStore() }`.

## Reinstall & logout

- **Keychain survives app deletion.** `SecureStorageBootstrap.run()` (called at
  launch by `AppAssembly`) wipes secure + encrypted stores on the first launch
  after a fresh install.
- On logout: `secureStore().removeAll()`, `encryptedStore().removeAll()`,
  then clear user-specific preferences.

## Keychain protection levels

| `KeychainStore.Protection` | Readable | Use for |
|---|---|---|
| `.afterFirstUnlock` (default) | after first unlock since boot | tokens used by background refresh |
| `.whenUnlocked` | only while unlocked | foreground-only secrets |
| `.passcodeSet` | only if a passcode exists; deleted if removed | high-value secrets |
| `.biometry` | Face ID / Touch ID each read; invalidated if biometrics change | payment PIN, vault |
