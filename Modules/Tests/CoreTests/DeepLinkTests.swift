//
//  DeepLinkTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation
@testable import Core
import Testing

struct DeepLinkTests {
    private let scheme = "eventpush"
    private let host = "eventpush.app"

    @Test func parsesCustomScheme() throws {
        let url = try #require(URL(string: "eventpush://events/42/organizer?ref=push"))
        let link = try #require(DeepLink(url: url, scheme: scheme, universalLinkHost: host))
        #expect(link.path == ["events", "42", "organizer"])
        #expect(link.query == ["ref": "push"])
    }

    @Test func parsesUniversalLink() throws {
        let url = try #require(URL(string: "https://eventpush.app/events/42"))
        let link = try #require(DeepLink(url: url, scheme: scheme, universalLinkHost: host))
        #expect(link.path == ["events", "42"])
    }

    @Test func rejectsForeignURL() throws {
        let url = try #require(URL(string: "https://evil.com/events/42"))
        #expect(DeepLink(url: url, scheme: scheme, universalLinkHost: host) == nil)
    }

    @Test func dropFirstKeepsQuery() {
        let link = DeepLink("events/42?ref=push").dropFirst()
        #expect(link.path == ["42"])
        #expect(link.query == ["ref": "push"])
        #expect(link.first == "42")
    }

    @MainActor
    @Test func deepLinkInboxQueuesUntilHandlerIsSet() {
        let inbox = DeepLinkInbox()
        inbox.post(DeepLink("a"))
        inbox.post(DeepLink("b"))
        #expect(inbox.pending.count == 2)
        var handled: [String] = []
        inbox.setHandler { handled.append($0.description); return true }
        inbox.post(DeepLink("c"))
        #expect(handled == ["/a", "/b", "/c"])
        #expect(inbox.pending.isEmpty)
    }
}
