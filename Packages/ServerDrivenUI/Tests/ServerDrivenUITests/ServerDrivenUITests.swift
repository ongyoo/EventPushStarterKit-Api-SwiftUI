//
//  ServerDrivenUITests.swift
//  ServerDrivenUI
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Foundation
@testable import ServerDrivenUI
import SwiftUI
import Testing
import UIKit

/// Every built-in component once, plus actions and conditions.
let sampleScreen = #"""
{
  "schemaVersion": 1,
  "id": "showcase",
  "title": "Showcase",
  "state": { "tab": "all", "name": "Ann", "notify": true, "volume": 0.4, "query": "" },
  "body": [
    { "type": "text", "props": { "text": "Hi {{name}}", "style": "largeTitle", "weight": "bold", "color": "#7952FC", "alignment": "center" } },
    { "type": "segmented", "props": { "bind": "tab", "options": [ { "title": "All", "value": "all" }, { "title": "Music", "value": "music", "icon": "music.note" } ] } },
    { "type": "text", "props": { "text": "Only music" }, "visibleIf": { "key": "tab", "equals": "music" } },
    { "type": "searchField", "props": { "bind": "query", "prompt": "Search" }, "action": { "type": "track", "event": "search" } },
    { "type": "banner", "props": { "imageUrl": "https://example.com/a.jpg", "title": "Sale", "subtitle": "Today", "badge": "NEW", "height": 180 },
      "action": { "type": "deepLink", "url": "eventpush://events/1" } },
    { "type": "section", "props": { "title": "Picks", "subtitle": "For {{name}}" }, "children": [
      { "type": "carousel", "props": { "itemWidth": 200 }, "children": [
        { "type": "card", "props": { "tint": "purple" }, "children": [ { "type": "icon", "props": { "systemName": "star.fill", "label": "Star" } }, { "type": "badge", "props": { "text": "Hot", "color": "red" } } ] }
      ] },
      { "type": "grid", "props": { "columns": 2 }, "children": [ { "type": "image", "props": { "url": "https://example.com/b.jpg", "height": 80, "cornerRadius": 12, "contentMode": "fit", "label": "Poster" } } ] }
    ] },
    { "type": "listItem", "props": { "icon": "bell", "title": "Alerts", "subtitle": "Daily", "value": "On" }, "action": { "type": "screen", "id": "alerts", "presentation": "sheet" } },
    { "type": "vstack", "props": { "spacing": 4, "alignment": "center" }, "children": [ { "type": "spacer", "props": { "size": 4 } }, { "type": "divider" } ] },
    { "type": "hstack", "children": [
      { "type": "toggle", "props": { "bind": "notify", "title": "Notify" } },
      { "type": "slider", "props": { "bind": "volume", "title": "Volume", "min": 0, "max": 1, "step": 0.1 } }
    ] },
    { "type": "glassGroup", "children": [
      { "type": "button", "props": { "title": "Buy", "icon": "cart", "style": "prominent", "fullWidth": true }, "action": { "type": "sequence", "actions": [ { "type": "track", "event": "buy" }, { "type": "deepLink" }, { "type": "setState", "key": "tab", "value": "music" } ] } },
      { "type": "button", "props": { "title": "Plain", "style": "plain" }, "action": { "type": "toggleState", "key": "notify" } },
      { "type": "button", "props": { "title": "Glass" }, "action": { "type": "openURL", "url": "https://example.com" } }
    ] },
    { "type": "futureComponent", "props": { "x": 1 } },
    { "type": "text", "props": { "text": "Broken action is ignored" }, "action": { "type": "deepLink" } }
  ],
  "toolbar": [
    { "type": "toolbarButton", "props": { "icon": "house", "title": "Home" }, "action": { "type": "dismiss" } },
    { "type": "toolbarButton", "props": { "icon": "arrow.clockwise", "title": "Reload" }, "action": { "type": "reload" } }
  ]
}
"""#

@MainActor
struct ServerDrivenUITests {
    private func decodeSample() throws -> DynamicScreen {
        try DynamicScreenDecoder.decode(Data(sampleScreen.utf8), appVersion: "1.0")
    }

    @Test func decodesTheWholeScreen() throws {
        let screen = try decodeSample()
        #expect(screen.id == "showcase")
        #expect(screen.title == "Showcase")
        #expect(screen.body.count == 12)
        #expect(screen.toolbar.count == 2)
        #expect(screen.state["volume"] == .number(0.4))
        // Broken action dropped, component kept.
        #expect(screen.body.last?.action == nil)
        #expect(screen.body.last?.string("text") == "Broken action is ignored")
    }

    @Test func actionsDecode() throws {
        let screen = try decodeSample()
        let actions = screen.body.compactMap(\.action)
        #expect(actions.contains(.deepLink(URL(string: "eventpush://events/1")!)))
        #expect(actions.contains(.screen(id: "alerts", presentation: .sheet)))
        #expect(actions.contains(.track(event: "search", params: [:])))
        let buttons = screen.body.first { $0.type == "glassGroup" }!.children
        // Broken step (no url) skipped inside the sequence.
        #expect(buttons[0].action == .sequence([.track(event: "buy", params: [:]), .setState(key: "tab", value: "music")]))
        #expect(buttons[1].action == .toggleState(key: "notify"))
        #expect(buttons[2].action == .openURL(URL(string: "https://example.com")!))
        #expect(screen.toolbar.compactMap(\.action) == [.dismiss, .reload])

        let custom = try JSONDecoder().decode(DynamicAction.self, from: Data(#"{"type":"share","text":"hi"}"#.utf8))
        #expect(custom == .custom(type: "share", props: ["text": "hi"]))
    }

    @Test func versionsAreChecked() {
        let newer = #"{"schemaVersion": 2, "id": "x", "body": []}"#
        #expect(throws: DynamicScreenError.unsupportedSchema(version: 2)) {
            try DynamicScreenDecoder.decode(Data(newer.utf8), appVersion: "9.0")
        }
        let needsApp = #"{"schemaVersion": 1, "id": "x", "minAppVersion": "1.10", "body": []}"#
        #expect(throws: DynamicScreenError.requiresAppVersion("1.10")) {
            try DynamicScreenDecoder.decode(Data(needsApp.utf8), appVersion: "1.9.2")
        }
        #expect((try? DynamicScreenDecoder.decode(Data(needsApp.utf8), appVersion: "1.10.0")) != nil)
        #expect(throws: DynamicScreenError.self) {
            try DynamicScreenDecoder.decode(Data("not json".utf8), appVersion: "1.0")
        }
        #expect(DynamicScreenDecoder.isVersion("1.2", olderThan: "1.2.1"))
        #expect(!DynamicScreenDecoder.isVersion("2.0", olderThan: "1.9"))
    }

    @Test func conditionsAndInterpolation() {
        let state: [String: JSONValue] = ["tab": "music", "vip": true, "empty": .null]
        #expect(DynamicCondition(key: "tab", equals: "music").isSatisfied(by: state))
        #expect(!DynamicCondition(key: "tab", notEquals: "music").isSatisfied(by: state))
        #expect(DynamicCondition(key: "vip", exists: true).isSatisfied(by: state))
        #expect(!DynamicCondition(key: "empty", exists: true).isSatisfied(by: state))
        #expect(DynamicCondition(key: "missing", exists: false).isSatisfied(by: state))

        let screenState = DynamicScreenState(["name": "Ann", "count": 3])
        #expect(screenState.interpolate("Hi {{name}}, {{count}} new") == "Hi Ann, 3 new")
        #expect(screenState.interpolate("No tokens") == "No tokens")
    }

    @Test func jsonValuesConvert() throws {
        let value = try JSONDecoder().decode(JSONValue.self, from: Data(#"{"a":[1,"2",true,null,1.5]}"#.utf8))
        let items = try #require(value.object?["a"]?.array)
        #expect(items[0].string == "1" && items[1].double == 2 && items[2].bool == true && items[3] == .null)
        #expect(items[4].string == "1.5")
        #expect(JSONValue.string("yes").bool == true && JSONValue.bool(true).double == 1 && JSONValue.number(0).bool == false)
        let encoded = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(JSONValue.self, from: encoded) == value)
    }

    @Test func stateActionsRunLocallyOthersGoToTheApp() throws {
        let screen = try decodeSample()
        var forwarded: [DynamicAction] = []
        let view = DynamicScreenView(screen: screen) { forwarded.append($0) }
        view.perform(.sequence([.setState(key: "tab", value: "music"), .toggleState(key: "notify"), .track(event: "x", params: [:])]))
        view.perform(.deepLink(URL(string: "eventpush://x")!))
        #expect(forwarded == [.track(event: "x", params: [:]), .deepLink(URL(string: "eventpush://x")!)])
    }

    @Test func registryIsExtensible() {
        var registry = DynamicComponentRegistry.standard
        #expect(registry.supportedTypes.contains("banner"))
        #expect(registry.renderer(for: "event_card") == nil)
        registry.register("event_card") { component, _ in Text(component.string("id") ?? "") }
        #expect(registry.renderer(for: "event_card") != nil)
    }

    @Test func colorsParse() {
        #expect(DynamicColor.parse("#7952FC") != nil)
        #expect(DynamicColor.parse("#7952FCCC") != nil)
        #expect(DynamicColor.parse("accent") != nil)
        #expect(DynamicColor.parse("teal") != nil)
        #expect(DynamicColor.parse("#XYZ") == nil)
        #expect(DynamicColor.parse("nope") == nil)
    }

    @Test func everyStandardComponentRenders() throws {
        let screen = try decodeSample()
        for style in [UIUserInterfaceStyle.light, .dark] {
            let host = UIHostingController(rootView: DynamicScreenView(screen: screen) { _ in })
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 2400))
            window.overrideUserInterfaceStyle = style
            window.rootViewController = host
            window.makeKeyAndVisible()
            host.view.layoutIfNeeded()
            #expect(host.view.bounds.width == 390)
        }
        let text = DynamicComponent(type: "text", props: ["style": "caption", "weight": "medium", "alignment": "trailing"])
        _ = (text.font, text.textAlignment, text.frameAlignment, text.horizontalAlignment)
        for style in ["title", "title2", "title3", "headline", "subheadline", "callout", "footnote", "body"] {
            _ = DynamicComponent(type: "text", props: ["style": .string(style), "weight": "semibold"]).font
        }
    }
}
