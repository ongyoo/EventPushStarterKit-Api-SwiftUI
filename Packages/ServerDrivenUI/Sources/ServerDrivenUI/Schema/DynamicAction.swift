//
//  DynamicAction.swift
//  ServerDrivenUI
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Foundation

/// What happens on tap. The app decides how to perform each one
/// (`DynamicActionHandler`); the renderer handles state changes itself.
///
///     { "type": "deepLink", "url": "eventpush://events/42" }
///     { "type": "screen", "id": "promo-detail", "presentation": "sheet" }
///     { "type": "track", "event": "promo_tapped", "params": { "slot": "hero" } }
///     { "type": "setState", "key": "tab", "value": "music" }
///     { "type": "sequence", "actions": [ ..., ... ] }
public indirect enum DynamicAction: Decodable, Sendable, Equatable {
    /// An in-app route (the app's deep link router).
    case deepLink(URL)
    /// A web page or another app.
    case openURL(URL)
    /// Another server-driven screen.
    case screen(id: String, presentation: Presentation)
    /// Analytics event (ids, categories only: no personal data).
    case track(event: String, params: [String: JSONValue])
    /// Changes screen state (bind / visibleIf react at once).
    case setState(key: String, value: JSONValue)
    /// Flips a boolean in screen state.
    case toggleState(key: String)
    case sequence([DynamicAction])
    case dismiss
    case reload
    /// Anything else: the app may support it (`custom` type, raw props).
    case custom(type: String, props: [String: JSONValue])

    public enum Presentation: String, Decodable, Sendable {
        case push, sheet, fullScreen
    }

    private enum CodingKeys: String, CodingKey {
        case type, url, id, presentation, event, params, key, value, actions
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "deepLink":
            self = .deepLink(try container.decode(URL.self, forKey: .url))
        case "openURL":
            self = .openURL(try container.decode(URL.self, forKey: .url))
        case "screen":
            let presentation = (try? container.decode(Presentation.self, forKey: .presentation)) ?? .push
            self = .screen(id: try container.decode(String.self, forKey: .id), presentation: presentation)
        case "track":
            let params = try container.decodeIfPresent([String: JSONValue].self, forKey: .params) ?? [:]
            self = .track(event: try container.decode(String.self, forKey: .event), params: params)
        case "setState":
            self = .setState(key: try container.decode(String.self, forKey: .key), value: try container.decode(JSONValue.self, forKey: .value))
        case "toggleState":
            self = .toggleState(key: try container.decode(String.self, forKey: .key))
        case "sequence":
            // Skip broken steps instead of dropping the whole sequence.
            let steps = try container.decode([FailableAction].self, forKey: .actions)
            self = .sequence(steps.compactMap(\.action))
        case "dismiss":
            self = .dismiss
        case "reload":
            self = .reload
        default:
            let raw = try JSONValue(from: decoder).object ?? [:]
            self = .custom(type: type, props: raw.filter { $0.key != "type" })
        }
    }
}

private struct FailableAction: Decodable {
    let action: DynamicAction?

    init(from decoder: any Decoder) throws {
        action = try? DynamicAction(from: decoder)
    }
}
