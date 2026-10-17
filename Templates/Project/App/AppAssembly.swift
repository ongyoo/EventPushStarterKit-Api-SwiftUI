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
import Foundation
import Navigation
import Platform

/// Composition root: the only place that knows every layer.
/// Runs once at launch: plugs Data implementations into Domain contracts,
/// picks infrastructure per environment, starts capabilities.
public enum AppAssembly {
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
            Log.app.warning("Device integrity: \(integrity.findings.map(\.rawValue), privacy: .public)")
        }
        if environment.useMockAPI {
            registerMockAPI(in: container)
        }
        DataAssembly.register(in: container)
        registerAnalytics(in: container)

        CrashMonitor.shared.start()
        _ = LocalizationManager.shared
        configureCapabilities(environment.features, container: container)
    }

    /// Starts only the capabilities switched on in Config/Features.xcconfig.
    @MainActor
    static func configureCapabilities(_ features: AppFeatures, container: Container) {
        if features.localNotifications {
            LocalNotificationCenter.shared.activate(categories: AppNotifications.categories, onResponse: { AppNotifications.handle($0) })
        }
        if features.backgroundTasks {
            BackgroundTaskService.shared.registerRefresh(every: 30 * 60) {
                // TODO: refresh data, e.g. `(try? await repository.items()) != nil`
                true
            }
            BackgroundTaskService.shared.registerProcessing(requiresPower: true) {
                await MainActor.run { ImageCache.clearMemory() }
                return true
            }
        }
        if features.silentPush {
            PushService.shared.on("refresh") { _ in
                // TODO: handle the silent push, return true if new data
                false
            }
        }
    }

    /// Where analytics events go: append SDK adapters to `providers`
    /// (template: Templates/Extensions/Analytics). Features call `Container.shared.analytics()`.
    static func registerAnalytics(in container: Container) {
        var providers: [any AnalyticsProvider] = []
        #if DEBUG
        providers.append(ConsoleAnalyticsProvider())
        #endif
        // `false` = opt-in (required by GDPR for non-essential analytics in the EU).
        let center = AnalyticsCenter(providers: providers, consentStore: container.preferences(), enabledByDefault: true)
        container.analyticsCenter.register { center }
        container.analytics.register { center }
    }

    /// Add each domain's fixtures here, e.g. `ProfileFixtures.responses`.
    static func registerMockAPI(in container: Container) {
        let fixtures: [String: Data] = [:]
        let responses = fixtures.mapValues { Result<Data, NetworkError>.success($0) }
        container.apiClient.register { MockAPIClient(responses: responses, delay: .milliseconds(300)) }
    }
}
