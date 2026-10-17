//
//  EventCategory.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation

/// Event type. API values: all, sports, entertainment, education, music, community.
public enum EventCategory: String, Codable, CaseIterable, Sendable {
    case all
    case sports
    case entertainment
    case education
    case music
    case community

    /// Unknown values from the API fall back to `.all` instead of failing
    /// the whole response.
    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = EventCategory(rawValue: raw) ?? .all
    }

    /// English name; features show `L10n.category(_:)` instead.
    public var title: String {
        switch self {
        case .all: "All"
        case .sports: "Sports"
        case .entertainment: "Entertainment"
        case .education: "Education"
        case .music: "Music"
        case .community: "Community"
        }
    }

    /// SF Symbol.
    public var iconName: String {
        switch self {
        case .all: "square.grid.2x2.fill"
        case .sports: "sportscourt.fill"
        case .entertainment: "film.fill"
        case .education: "book.fill"
        case .music: "music.note.list"
        case .community: "person.3.fill"
        }
    }
}
