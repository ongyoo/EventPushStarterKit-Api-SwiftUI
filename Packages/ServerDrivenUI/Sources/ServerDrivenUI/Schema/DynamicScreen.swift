//
//  DynamicScreen.swift
//  ServerDrivenUI
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Foundation

/// A whole screen sent by the backend. See `docs/SCHEMA.md` for the format.
///
///     {
///       "schemaVersion": 1,
///       "id": "promo",
///       "title": "Songkran deals",
///       "state": { "tab": "all" },
///       "body": [ { "type": "text", "props": { "text": "Hello", "style": "title" } } ],
///       "toolbar": [ ... ]
///     }
public struct DynamicScreen: Decodable, Sendable, Equatable {
    public let schemaVersion: Int
    public let id: String
    public let title: String?
    /// Lowest app version that understands this screen (`"1.2.0"`).
    public let minAppVersion: String?
    /// Initial values for `bind` / `visibleIf` / `setState`.
    public let state: [String: JSONValue]
    public let body: [DynamicComponent]
    /// Floating glass toolbar at the bottom.
    public let toolbar: [DynamicComponent]
    /// `screen_view` name for analytics. Default: `dynamic_<id>`.
    public let analyticsName: String?

    public init(
        schemaVersion: Int = DynamicScreenDecoder.supportedSchemaVersion,
        id: String,
        title: String? = nil,
        minAppVersion: String? = nil,
        state: [String: JSONValue] = [:],
        body: [DynamicComponent],
        toolbar: [DynamicComponent] = [],
        analyticsName: String? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.title = title
        self.minAppVersion = minAppVersion
        self.state = state
        self.body = body
        self.toolbar = toolbar
        self.analyticsName = analyticsName
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, id, title, minAppVersion, state, body, toolbar, analyticsName
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        minAppVersion = try container.decodeIfPresent(String.self, forKey: .minAppVersion)
        state = try container.decodeIfPresent([String: JSONValue].self, forKey: .state) ?? [:]
        body = try container.decodeIfPresent([DynamicComponent].self, forKey: .body) ?? []
        toolbar = try container.decodeIfPresent([DynamicComponent].self, forKey: .toolbar) ?? []
        analyticsName = try container.decodeIfPresent(String.self, forKey: .analyticsName)
    }
}

/// One UI element: `type` picks the renderer, `props` configure it.
public struct DynamicComponent: Decodable, Sendable, Equatable, Identifiable {
    public let type: String
    /// Stable id (animations, analytics). Generated when missing.
    public let id: String
    public let props: [String: JSONValue]
    public let children: [DynamicComponent]
    public let action: DynamicAction?
    /// Shown only when the condition holds (e.g. the selected segment).
    public let visibleIf: DynamicCondition?

    public init(
        type: String,
        id: String = UUID().uuidString,
        props: [String: JSONValue] = [:],
        children: [DynamicComponent] = [],
        action: DynamicAction? = nil,
        visibleIf: DynamicCondition? = nil
    ) {
        self.type = type
        self.id = id
        self.props = props
        self.children = children
        self.action = action
        self.visibleIf = visibleIf
    }

    private enum CodingKeys: String, CodingKey {
        case type, id, props, children, action, visibleIf
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        props = try container.decodeIfPresent([String: JSONValue].self, forKey: .props) ?? [:]
        children = try container.decodeIfPresent([DynamicComponent].self, forKey: .children) ?? []
        // A broken action must not break the whole screen.
        action = try? container.decodeIfPresent(DynamicAction.self, forKey: .action)
        visibleIf = try? container.decodeIfPresent(DynamicCondition.self, forKey: .visibleIf)
    }

    // MARK: - Typed props

    public func string(_ key: String) -> String? { props[key]?.string }
    public func double(_ key: String) -> Double? { props[key]?.double }
    public func bool(_ key: String) -> Bool? { props[key]?.bool }
    public func strings(_ key: String) -> [String] { props[key]?.array?.compactMap(\.string) ?? [] }
}

/// `{ "key": "tab", "equals": "music" }`, `{ "key": "isMember", "equals": true }`,
/// `{ "key": "promo", "exists": true }`, `{ "key": "tab", "notEquals": "all" }`.
public struct DynamicCondition: Decodable, Sendable, Equatable {
    public let key: String
    public let equals: JSONValue?
    public let notEquals: JSONValue?
    public let exists: Bool?

    public init(key: String, equals: JSONValue? = nil, notEquals: JSONValue? = nil, exists: Bool? = nil) {
        self.key = key
        self.equals = equals
        self.notEquals = notEquals
        self.exists = exists
    }

    public func isSatisfied(by state: [String: JSONValue]) -> Bool {
        let value = state[key]
        if let exists, exists != (value != nil && value != .null) { return false }
        if let equals, value != equals { return false }
        if let notEquals, value == notEquals { return false }
        return true
    }
}
