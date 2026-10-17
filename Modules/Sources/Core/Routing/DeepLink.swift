//
//  DeepLink.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation

/// A parsed deep link: path segments + query.
///
/// Both forms produce the same link:
/// - Custom scheme:  `eventpush://events/42/organizer?ref=push`
/// - Universal link: `https://eventpush.app/events/42/organizer?ref=push`
///
///     link.path    // ["events", "42", "organizer"]
///     link.query   // ["ref": "push"]
///
/// Routing works like a relay: each coordinator reads `link.first`,
/// handles it, then passes `link.dropFirst()` to its child. So any
/// screen at any depth can be reached, and no coordinator needs to know
/// more than its own segment.
public struct DeepLink: Sendable, Hashable, CustomStringConvertible {
    public let path: [String]
    public let query: [String: String]

    /// `DeepLink(path: ["events", "42"], query: ["ref": "push"])`
    public init(path: [String], query: [String: String] = [:]) {
        self.path = path.filter { !$0.isEmpty }
        self.query = query
    }

    /// `DeepLink("events/42?ref=push")` — handy in tests and push payloads.
    public init(_ string: String) {
        let parts = string.split(separator: "?", maxSplits: 1).map(String.init)
        let path = (parts.first ?? "").split(separator: "/").map(String.init)
        let query = parts.count > 1
            ? URLComponents(string: "?\(parts[1])")?.queryItems ?? []
            : []
        self.init(path: path, query: Self.dictionary(from: query))
    }

    /// Returns nil when the URL is neither our scheme nor our universal-link host.
    public init?(url: URL, scheme: String, universalLinkHost: String) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        let pathSegments = components.path.split(separator: "/").map(String.init)

        switch components.scheme?.lowercased() {
        case scheme.lowercased():
            // eventpush://events/42 -> host "events" is the first segment.
            self.init(path: [components.host].compactMap { $0 } + pathSegments,
                      query: Self.dictionary(from: components.queryItems ?? []))
        case "https" where components.host?.lowercased() == universalLinkHost.lowercased():
            self.init(path: pathSegments, query: Self.dictionary(from: components.queryItems ?? []))
        default:
            return nil
        }
    }

    /// First segment, e.g. "events".
    public var first: String? { path.first }

    /// The link without its first `count` segments (query is kept).
    public func dropFirst(_ count: Int = 1) -> DeepLink {
        DeepLink(path: Array(path.dropFirst(count)), query: query)
    }

    /// `true` when every segment has been consumed (the current screen is the target).
    public var isEmpty: Bool { path.isEmpty }

    public var description: String {
        let queryString = query.isEmpty ? "" : "?" + query.map { "\($0)=\($1)" }.sorted().joined(separator: "&")
        return "/" + path.joined(separator: "/") + queryString
    }

    private static func dictionary(from items: [URLQueryItem]) -> [String: String] {
        Dictionary(items.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { _, last in last })
    }
}
