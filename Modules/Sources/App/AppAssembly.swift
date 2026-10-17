//
//  AppAssembly.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import DataLayer
import DataSources
import DesignSystem
import Domain
import Foundation
import Navigation
import Platform
import ServerDrivenUI

/// Composition root: the only place that knows every layer.
/// Runs once at launch, before any screen: plugs Data implementations into
/// Domain contracts, picks infrastructure per environment, starts capabilities.
public enum AppAssembly {
    /// Call first thing in `application(_:didFinishLaunchingWithOptions:)`.
    @MainActor
    public static func configure(
        environment: AppEnvironment = .current,
        container: Container = .shared
    ) {
        container.appEnvironment.register { environment }

        // Keychain survives reinstall: wipe secrets left by a previous install.
        SecureStorageBootstrap.run(storesToWipe: [container.secureStore(), container.encryptedStore()])

        ImageCache.configure(memoryLimitMB: 100, diskLimitMB: 300)

        // iOS 26 keeps its Liquid Glass back button; older systems get a similar round one.
        Navigator.defaultBackButton = .belowIOS26(.circle())

        let integrity = DeviceIntegrity.check()
        if integrity.isCompromised {
            // Decide your policy here: report to backend, hide sensitive features...
            Log.app.warning("Device integrity: \(integrity.findings.map(\.rawValue), privacy: .public)")
        }

        if environment.useMockAPI {
            registerMockAPI(in: container)
        }
        DataAssembly.register(in: container, dynamicScreenSchemaVersion: DynamicScreenDecoder.supportedSchemaVersion)
        registerAnalytics(in: container)

        CrashMonitor.shared.start()
        _ = LocalizationManager.shared
        configureCapabilities(environment.features, container: container)
        Log.app.info("Configured for \(environment.name.rawValue, privacy: .public) (mock API: \(environment.useMockAPI))")
    }

    /// Starts only the capabilities switched on in Config/Features.xcconfig.
    /// Must run inside `application(_:didFinishLaunchingWithOptions:)`
    /// (background tasks have to be registered before it returns).
    @MainActor
    static func configureCapabilities(_ features: AppFeatures, container: Container) {
        if features.localNotifications {
            LocalNotificationCenter.shared.activate(categories: AppNotifications.categories, onResponse: { AppNotifications.handle($0) })
        }
        if features.backgroundTasks {
            let repository = container.eventRepository()
            BackgroundTaskService.shared.registerRefresh(every: 30 * 60) {
                // Warm the cache so the app opens with fresh events.
                (try? await repository.events()) != nil
            }
            BackgroundTaskService.shared.registerProcessing(requiresPower: true) {
                await MainActor.run { ImageCache.clearMemory() }
                return true
            }
        }
        if features.silentPush {
            let repository = container.eventRepository()
            PushService.shared.on("events.refresh") { _ in
                (try? await repository.events()) != nil
            }
        }
    }

    /// Where analytics events go. Add an SDK here: write its adapter in
    /// Platform/Analytics (template: Templates/Extensions/Analytics) and
    /// append it to `providers`. Every screen and feature keeps working unchanged.
    static func registerAnalytics(in container: Container) {
        var providers: [any AnalyticsProvider] = []
        #if DEBUG
        providers.append(ConsoleAnalyticsProvider())   // see events in the Xcode console
        #endif
        // providers.append(FirebaseAnalyticsProvider())

        // `true` = opt-out model (user can turn it off in Settings > Privacy).
        // Use `false` (opt-in) where the law requires consent first, e.g. EU users.
        let center = AnalyticsCenter(providers: providers, consentStore: container.preferences(), enabledByDefault: true)
        container.analyticsCenter.register { center }
        container.analytics.register { center }
    }

    /// Offline mode: every domain contributes its JSON fixtures.
    static func registerMockAPI(in container: Container) {
        let fixtures = EventFixtures.responses.merging(DynamicScreenFixtures.responses) { first, _ in first }
        let responses = fixtures.mapValues { Result<Data, NetworkError>.success($0) }
        container.apiClient.register { MockAPIClient(responses: responses, delay: .milliseconds(300)) }
    }
}
