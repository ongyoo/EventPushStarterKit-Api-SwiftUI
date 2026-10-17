//
//  FirebaseAnalyticsProvider.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

// TEMPLATE (not compiled). Adapter for Firebase Analytics.
//
// 1. Add the package to Modules/Package.swift, used by Platform only:
//      .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0")
//      .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk")   // in Platform's dependencies
// 2. Copy this file to Modules/Sources/Platform/Analytics/.
// 3. AppAssembly.registerAnalytics: providers.append(FirebaseAnalyticsProvider())
//    (call FirebaseApp.configure() first, in AppAssembly.configure).
// 4. Declare collected data in PrivacyInfo.xcprivacy (NSPrivacyCollectedDataTypes).
//
// Features never change: they keep calling `analytics.track(...)`.

import Core
import FirebaseAnalytics

public struct FirebaseAnalyticsProvider: AnalyticsProvider {
    public init() {}

    public func send(_ event: AnalyticsEvent) {
        if event.name == "screen_view" {
            Analytics.logEvent(AnalyticsEventScreenView, parameters: [
                AnalyticsParameterScreenName: event.parameters["screen_name"]?.description ?? "",
            ])
            return
        }
        Analytics.logEvent(event.name, parameters: event.parameters.mapValues(\.firebaseValue))
    }

    public func setUserID(_ id: String?) {
        Analytics.setUserID(id)
    }

    public func setUserProperty(_ value: String?, forName name: String) {
        Analytics.setUserProperty(value, forName: name)
    }

    public func reset() {
        Analytics.resetAnalyticsData()
        Analytics.setAnalyticsCollectionEnabled(false)
    }
}

private extension AnalyticsValue {
    var firebaseValue: Any {
        switch self {
        case let .string(value): value
        case let .int(value): value
        case let .double(value): value
        case let .bool(value): value ? 1 : 0   // Firebase has no booleans
        }
    }
}
