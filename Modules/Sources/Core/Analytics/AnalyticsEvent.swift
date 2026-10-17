//
//  AnalyticsEvent.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Foundation

/// A parameter value. Only simple types: every analytics SDK accepts them.
public enum AnalyticsValue: Sendable, Hashable, CustomStringConvertible {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)

    public var description: String {
        switch self {
        case let .string(value): value
        case let .int(value): "\(value)"
        case let .double(value): "\(value)"
        case let .bool(value): "\(value)"
        }
    }
}

extension AnalyticsValue: ExpressibleByStringLiteral, ExpressibleByIntegerLiteral,
    ExpressibleByFloatLiteral, ExpressibleByBooleanLiteral {
    public init(stringLiteral value: String) { self = .string(value) }
    public init(integerLiteral value: Int) { self = .int(value) }
    public init(floatLiteral value: Double) { self = .double(value) }
    public init(booleanLiteral value: Bool) { self = .bool(value) }
}

/// Something the user did, in snake_case, SDK-agnostic.
///
/// Declare each event once, next to the feature that sends it:
///
///     extension AnalyticsEvent {
///         static func eventSelected(id: String, source: String) -> AnalyticsEvent {
///             AnalyticsEvent("event_selected", ["event_id": .string(id), "source": .string(source)])
///         }
///     }
///
///     analytics.track(.eventSelected(id: event.id, source: "popular"))
public struct AnalyticsEvent: Sendable, Hashable {
    public let name: String
    public let parameters: [String: AnalyticsValue]

    public init(_ name: String, _ parameters: [String: AnalyticsValue] = [:]) {
        self.name = name
        self.parameters = parameters
    }

    /// Sent automatically by `Navigator` when a screen appears.
    public static func screenView(_ screenName: String) -> AnalyticsEvent {
        AnalyticsEvent("screen_view", ["screen_name": .string(screenName)])
    }
}

// MARK: - Privacy and SDK limits

public extension AnalyticsEvent {
    /// Common SDK limits (Firebase: 40-char names, 25 parameters, 100-char values).
    enum Limits {
        public static let nameLength = 40
        public static let parameterCount = 25
        public static let valueLength = 100
    }

    /// Parameter names that suggest personal data. Such parameters are dropped:
    /// send ids, counts and categories, never who the user is.
    static let personalDataHints = [
        "email", "phone", "password", "passcode", "token", "secret", "address",
        "first_name", "last_name", "full_name", "birth", "card", "cvv", "national_id", "ssn",
    ]

    /// The event with SDK limits applied and personal data removed, plus what
    /// was dropped (logged by the analytics center). `nil` if the name is invalid.
    func sanitized() -> (event: AnalyticsEvent?, dropped: [String]) {
        guard Self.isValidName(name) else { return (nil, ["event name '\(name)'"]) }
        var dropped: [String] = []
        var clean: [String: AnalyticsValue] = [:]
        for key in parameters.keys.sorted() {
            guard let value = parameters[key] else { continue }
            if !Self.isValidName(key) {
                dropped.append("\(key) (invalid name)")
            } else if Self.personalDataHints.contains(where: key.contains) || Self.looksLikeEmail(value) {
                dropped.append("\(key) (personal data)")
            } else if clean.count >= Limits.parameterCount {
                dropped.append("\(key) (over \(Limits.parameterCount) parameters)")
            } else if case let .string(text) = value, text.count > Limits.valueLength {
                clean[key] = .string(String(text.prefix(Limits.valueLength)))
            } else {
                clean[key] = value
            }
        }
        return (AnalyticsEvent(name, clean), dropped)
    }

    /// snake_case, starts with a letter, at most 40 characters, no reserved prefix.
    static func isValidName(_ name: String) -> Bool {
        guard let first = name.first, first.isLetter, first.isLowercase, name.count <= Limits.nameLength else { return false }
        guard !["firebase_", "google_", "ga_"].contains(where: name.hasPrefix) else { return false }
        return name.allSatisfy { ($0.isLetter && $0.isLowercase) || $0.isNumber || $0 == "_" }
    }

    private static func looksLikeEmail(_ value: AnalyticsValue) -> Bool {
        guard case let .string(text) = value else { return false }
        return text.contains("@") && text.contains(".")
    }
}
