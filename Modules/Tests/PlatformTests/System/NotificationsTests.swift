//
//  NotificationsTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Foundation
@testable import Platform
import Testing
import UserNotifications

@MainActor
struct NotificationsTests {
    @Test func buildsRequestWithEveryOption() throws {
        let notification = LocalNotification(
            id: "n1", title: "Title", subtitle: "Sub", body: "Body",
            trigger: .after(30), sound: .named("ding.caf"), badge: 3,
            group: "events", categoryID: "event",
            deepLink: "events/1", priority: .timeSensitive, relevance: 2,
            userInfo: ["source": "test"]
        )
        let request = try notification.makeRequest()
        let content = request.content
        #expect(request.identifier == "n1")
        #expect(content.subtitle == "Sub")
        #expect(content.badge == 3)
        #expect(content.threadIdentifier == "events")
        #expect(content.categoryIdentifier == "event")
        #expect(content.relevanceScore == 1)
        #expect(content.interruptionLevel == .timeSensitive)
        #expect(content.userInfo["deeplink"] as? String == "events/1")
        #expect(content.userInfo["source"] as? String == "test")
        #expect((request.trigger as? UNTimeIntervalNotificationTrigger)?.timeInterval == 30)
    }

    @Test func triggersAndSounds() throws {
        let now = try LocalNotification(title: "a", body: "b", sound: .none, priority: .passive).makeRequest()
        #expect((now.trigger as? UNTimeIntervalNotificationTrigger)?.timeInterval == 1)
        #expect(now.content.sound == nil)
        #expect(now.content.interruptionLevel == .passive)

        let repeating = try LocalNotification(title: "a", body: "b", trigger: .after(5, repeats: true)).makeRequest()
        #expect((repeating.trigger as? UNTimeIntervalNotificationTrigger)?.timeInterval == 60, "iOS minimum for repeats")

        let daily = try LocalNotification(title: "a", body: "b", trigger: .at(DateComponents(hour: 9), repeats: true)).makeRequest()
        #expect((daily.trigger as? UNCalendarNotificationTrigger)?.repeats == true)
    }

    @Test func categoriesMapActions() {
        let category = NotificationCategory(id: "event", actions: [
            .init(id: "remind", title: "Remind", opensApp: true, requiresUnlock: true),
            .init(id: "reply", title: "Reply", textInput: "Message"),
            .init(id: "cancel", title: "Cancel", style: .destructive),
        ], hiddenPreviewsBody: "%u events").makeCategory()
        #expect(category.identifier == "event")
        #expect(category.actions.count == 3)
        #expect(category.actions[1] is UNTextInputNotificationAction)
        #expect(category.actions[2].options.contains(.destructive))
        #expect(NotificationCategory(id: "plain", actions: []).makeCategory().actions.isEmpty)
    }

    @Test func responsesAreParsedAndRoutedToDeepLinkInbox() {
        let opened = LocalNotificationCenter.makeResponse(actionID: UNNotificationDefaultActionIdentifier, text: nil, notificationID: "n1", userInfo: ["deeplink": "events/1", 1: 2])
        let dismissed = LocalNotificationCenter.makeResponse(actionID: UNNotificationDismissActionIdentifier, text: nil, notificationID: "n1", userInfo: [:])
        let reply = LocalNotificationCenter.makeResponse(actionID: "reply", text: "Hi", notificationID: "n1", userInfo: [:])
        #expect(opened.action == .opened && opened.deepLink == "events/1")
        #expect(dismissed.action == .dismissed)
        #expect(reply.action == .custom(id: "reply", text: "Hi"))

        let center = LocalNotificationCenter()
        var received: [NotificationResponse] = []
        center.activate(categories: []) { received.append($0) }
        var routed: [DeepLink] = []
        DeepLinkInbox.shared.setHandler { routed.append($0); return true }
        center.handle(opened)
        center.handle(dismissed)
        #expect(routed == [DeepLink("events/1")])
        #expect(received.count == 2)
    }

    @Test func pushServiceRoutesByType() async {
        let push = PushService()
        var tokens: [String] = []
        push.onTokenChange = { tokens.append($0) }
        push.didRegister(deviceToken: Data([0xAB, 0x01]))
        push.didFailToRegister(URLError(.notConnectedToInternet))
        #expect(tokens == ["ab01"] && push.deviceToken == "ab01")

        push.on("refresh") { payload in payload["id"] == "1" }
        #expect(await push.handle(["type": "refresh", "id": "1"]) == .newData)
        #expect(await push.handle(["type": "refresh", "id": "2"]) == .noData)
        #expect(await push.handle(["type": "unknown"]) == .noData)
    }

    @Test func backgroundTaskIDsUseBundleIdentifier() {
        #expect(BackgroundTaskID.refresh.rawValue.hasSuffix(".refresh"))
        #expect(BackgroundTaskID.processing.rawValue.hasSuffix(".processing"))
        #expect(BackgroundTaskService().registeredIDs.isEmpty)
    }

    @Test func unpermittedBackgroundTaskIsIgnoredInsteadOfCrashing() {
        let service = BackgroundTaskService(infoDictionary: [:])
        service.registerRefresh { true }
        service.registerProcessing { true }
        service.scheduleAll()
        #expect(service.registeredIDs.isEmpty)
    }

    @Test func notificationCenterIsSafeOutsideAnApp() async throws {
        let center = LocalNotificationCenter()
        center.activate(categories: [NotificationCategory(id: "x", actions: [])])
        try await center.schedule(LocalNotification(title: "a", body: "b"))
        try await center.schedule([LocalNotification(title: "c", body: "d")])
        center.cancel(ids: ["a"])
        center.cancelAll()
        center.removeDelivered(ids: ["a"])
        center.removeAllDelivered()
        await center.removeGroup("g")
        await center.setBadge(0)
        #expect(await center.pendingIDs().isEmpty)
        #expect(await center.deliveredIDs().isEmpty)
    }
}
