//
//  PermissionsTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import ActivityKit
import AppTrackingTransparency
import AVFoundation
import Contacts
import Core
import CoreLocation
import EventKit
import Photos
@testable import Platform
import Testing
import UserNotifications

@MainActor
struct PermissionsTests {
    @Test func statusHelpers() {
        #expect(PermissionStatus.limited.isGranted && PermissionStatus.provisional.isGranted)
        #expect(!PermissionStatus.denied.isGranted && PermissionStatus.denied.needsSettings)
        #expect(PermissionStatus.notDetermined.canRequest && !PermissionStatus.restricted.canRequest)
        #expect(Permission.allCases.allSatisfy { !$0.systemImage.isEmpty && $0.id == $0.rawValue })
        #expect(Permission.notifications.usageDescriptionKey == nil)
    }

    @Test func missingPurposeStringNeverCrashes() async {
        let center = PermissionCenter(infoDictionary: [:])
        for permission in Permission.allCases where permission.usageDescriptionKey != nil {
            guard case .unavailable = await center.request(permission) else {
                Issue.record("\(permission) should be unavailable without its Info.plist key")
                continue
            }
        }
    }

    @Test func mapsEverySystemStatus() {
        #expect(PermissionCenter.map(UNAuthorizationStatus.notDetermined) == .notDetermined)
        #expect(PermissionCenter.map(UNAuthorizationStatus.authorized) == .authorized)
        #expect(PermissionCenter.map(UNAuthorizationStatus.provisional) == .provisional)
        #expect(PermissionCenter.map(UNAuthorizationStatus.ephemeral) == .limited)
        #expect(PermissionCenter.map(UNAuthorizationStatus.denied) == .denied)

        #expect(PermissionCenter.map(AVAuthorizationStatus.notDetermined) == .notDetermined)
        #expect(PermissionCenter.map(AVAuthorizationStatus.authorized) == .authorized)
        #expect(PermissionCenter.map(AVAuthorizationStatus.restricted) == .restricted)
        #expect(PermissionCenter.map(AVAuthorizationStatus.denied) == .denied)

        #expect(PermissionCenter.map(PHAuthorizationStatus.notDetermined) == .notDetermined)
        #expect(PermissionCenter.map(PHAuthorizationStatus.authorized) == .authorized)
        #expect(PermissionCenter.map(PHAuthorizationStatus.limited) == .limited)
        #expect(PermissionCenter.map(PHAuthorizationStatus.restricted) == .restricted)
        #expect(PermissionCenter.map(PHAuthorizationStatus.denied) == .denied)

        #expect(PermissionCenter.map(CLAuthorizationStatus.notDetermined) == .notDetermined)
        #expect(PermissionCenter.map(CLAuthorizationStatus.authorizedWhenInUse) == .authorized)
        #expect(PermissionCenter.map(CLAuthorizationStatus.restricted) == .restricted)
        #expect(PermissionCenter.map(CLAuthorizationStatus.denied) == .denied)

        #expect(PermissionCenter.map(CNAuthorizationStatus.notDetermined) == .notDetermined)
        #expect(PermissionCenter.map(CNAuthorizationStatus.authorized) == .authorized)
        if #available(iOS 18.0, *) {
            #expect(PermissionCenter.map(CNAuthorizationStatus.limited) == .limited)
        }
        #expect(PermissionCenter.map(CNAuthorizationStatus.restricted) == .restricted)
        #expect(PermissionCenter.map(CNAuthorizationStatus.denied) == .denied)

        #expect(PermissionCenter.map(EKAuthorizationStatus.notDetermined) == .notDetermined)
        #expect(PermissionCenter.map(EKAuthorizationStatus.fullAccess) == .authorized)
        #expect(PermissionCenter.map(EKAuthorizationStatus.writeOnly) == .limited)
        #expect(PermissionCenter.map(EKAuthorizationStatus.restricted) == .restricted)
        #expect(PermissionCenter.map(EKAuthorizationStatus.denied) == .denied)

        #expect(PermissionCenter.map(ATTrackingManager.AuthorizationStatus.notDetermined) == .notDetermined)
        #expect(PermissionCenter.map(ATTrackingManager.AuthorizationStatus.authorized) == .authorized)
        #expect(PermissionCenter.map(ATTrackingManager.AuthorizationStatus.restricted) == .restricted)
        #expect(PermissionCenter.map(ATTrackingManager.AuthorizationStatus.denied) == .denied)
    }

    @Test func readsStatusesWithoutPrompting() async {
        let keys = Dictionary(uniqueKeysWithValues: Permission.allCases.compactMap(\.usageDescriptionKey).map { ($0, "Reason") })
        let statuses = await PermissionCenter(infoDictionary: keys).statuses()
        #expect(statuses.count == Permission.allCases.count)
    }

    @Test func featureFlagsParseFromInfoPlist() {
        let features = AppFeatures(["localNotifications": "YES", "backgroundTasks": "yes", "silentPush": "NO"])
        #expect(features.localNotifications && features.backgroundTasks)
        #expect(!features.silentPush && !features.liveActivities && !features.siri)
        #expect(AppFeatures(nil) == .none)
        #expect(AppFeatures.all.siri)
    }

    @Test func crashMonitorStartsOnce() {
        struct Reporter: CrashReporting { func report(_ diagnostic: CrashDiagnostic) {} }
        let monitor = CrashMonitor()
        monitor.start(reporter: Reporter())
        monitor.start()
        #expect(monitor.reporter != nil)
    }

    @Test func liveActivityServiceIsOffWhenFeatureIsOff() async throws {
        let service = LiveActivityService<DemoAttributes>(isFeatureEnabled: false)
        #expect(!service.isAvailable)
        #expect(throws: LiveActivityService<DemoAttributes>.Failure.disabledByApp) {
            try service.start(DemoAttributes(), state: .init(value: 1))
        }
        await service.update("missing", state: .init(value: 2))
        await service.end("missing")
        await service.endAll()
        #expect(service.activeIDs.isEmpty)
    }
}

struct DemoAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable { var value: Int }
}
