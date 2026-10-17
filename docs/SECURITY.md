# Security

What the kit does for you, and what you still have to do.

## Built in

| Area | How | Where |
|---|---|---|
| Secrets at rest | Keychain `ThisDeviceOnly`, never synced/backed up | `DataSources/Storage/KeychainStore` |
| Sensitive files | AES-GCM + Data Protection + excluded from backup | `EncryptedFileStore` |
| Reinstall leftovers | Secure stores wiped on first launch after install | `SecureStorageBootstrap` |
| Biometrics | `BiometricAuthenticator` for actions; Keychain `.biometry` for data | `Platform/Security` |
| Transport | HTTPS only (ATS on, no exceptions); optional **SSL pinning** | `AlamofireAPIClient(pinnedHosts:)` |
| Auth header | Bearer token injected per request, skipped for public endpoints | `AccessTokenProvider`, `Endpoint.requiresAuth` |
| Logs | `os.Logger`, secrets never logged, network logs Debug only | `Log`, `NetworkLogger` |
| App switcher | Optional blur of the snapshot | `AppCoordinator.hidesContentInAppSwitcher = true` |
| Screenshots / recording | Hide a view from captures | `.hiddenFromScreenCapture()` / `SecureContent { }` |
| Clipboard | Expiring, local-only copy (no Universal Clipboard) | `SecurePasteboard.copy(_:expiresAfter:)` |
| Jailbreak / hooking / debugger | Signals, reported at launch | `DeviceIntegrity.check()` |
| Deep links | Only our scheme / our host accepted; unknown paths rejected | `DeepLink(url:scheme:universalLinkHost:)` |
| Permissions | Never asked without a purpose string; ask in context | `PermissionCenter` |
| Crash safety | Lint blocks crash patterns | `make lint` |

## Enable SSL pinning

1. Export the server certificate(s) as `.cer` (DER) – current **and** next one.
2. Add them to `App/Resources`.
3. `Config/Base.xcconfig`: `SSL_PINNED_HOSTS = api.example.com`
4. Test on a device with a proxy (Charles/Proxyman): requests must fail.

Rotate certificates by shipping the new one **before** the server switches.

## Checklist before release

- [ ] No secrets in the repo, xcconfig or Info.plist (use CI secrets / server).
- [ ] Release build: `USE_MOCK_API = NO`, correct `API_BASE_URL`.
- [ ] Remove Info.plist purpose strings (and `PermissionCenter` cases) you don't use.
- [ ] Decide the policy for `DeviceIntegrity` findings (block, warn, report).
- [ ] Sensitive screens: `hiddenFromScreenCapture()`, app-switcher blur.
- [ ] Logout clears secure + encrypted stores.
- [ ] Push entitlement `aps-environment` = `production` for App Store builds.
- [ ] Privacy manifest (`PrivacyInfo.xcprivacy`) lists the APIs you use (UserDefaults, file timestamps...).

## Limits (be honest)

Client-side checks (jailbreak detection, pinning) **raise the bar**; a
determined attacker on their own device can bypass them. Real security is on
the server: short-lived tokens, server-side validation, rate limits.
