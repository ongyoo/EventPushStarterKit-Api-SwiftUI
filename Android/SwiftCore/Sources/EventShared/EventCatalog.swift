//
//  EventCatalog.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//


#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// How results are ordered.
public enum EventSort: String, Sendable, Codable, CaseIterable {
    case soonest, popular, cheapest
}

/// What the user is looking for.
public struct EventQuery: Sendable, Codable, Hashable {
    public var text: String
    /// `nil` = all categories.
    public var category: EventCategory?
    public var sort: EventSort

    public init(text: String = "", category: EventCategory? = nil, sort: EventSort = .soonest) {
        self.text = text
        self.category = category
        self.sort = sort
    }
}

/// All business rules for browsing events: search, filter, sort, group.
/// Immutable, so it is safe to use from any thread.
///
///     let catalog = try EventCatalog(json: data)
///     let page = catalog.snapshot(for: EventQuery(text: "bangkok"), formatter: formatter, now: .now)
public struct EventCatalog: Sendable {
    public let events: [Event]

    public init(events: [Event]) {
        self.events = events
    }

    /// Decodes the API / fixture format (`[EventDTO]`, ISO 8601 dates).
    public init(json: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.init(events: try decoder.decode([Event].self, from: json))
    }

    /// Events matching `query`, in the requested order.
    ///
    /// Search is case-insensitive, matches title, city, venue and organizer,
    /// and every word must match ("rock bangkok").
    public func search(_ query: EventQuery) -> [Event] {
        let words = query.text.lowercased().split(whereSeparator: \.isWhitespace).map(String.init)
        let matches = events.filter { event in
            guard query.category == nil || event.category == query.category else { return false }
            let haystack = [event.title, event.city, event.venue, event.organizer].joined(separator: " ").lowercased()
            return words.allSatisfy { haystack.contains($0) }
        }
        switch query.sort {
        case .soonest: return matches.sorted { ($0.startsAt, $0.id) < ($1.startsAt, $1.id) }
        case .popular: return matches.sorted { ($0.favorites, $1.id) > ($1.favorites, $0.id) }
        case .cheapest: return matches.sorted { ($0.price, $0.id) < ($1.price, $1.id) }
        }
    }

    /// Number of events per category (for filter chips), in `EventCategory` order.
    public func categoryCounts() -> [(category: EventCategory, count: Int)] {
        EventCategory.allCases.compactMap { category in
            let count = events.lazy.filter { $0.category == category }.count
            return count > 0 ? (category, count) : nil
        }
    }

    /// Everything a list screen needs, already formatted. One call per keystroke.
    public func snapshot(for query: EventQuery, formatter: EventFormatter, now: Date) -> CatalogSnapshot {
        let results = search(query)
        let sections: [CatalogSnapshot.Section]
        if query.sort == .soonest {
            // Group by local month, keeping the sorted order.
            var grouped: [(key: Int, title: String, events: [Event])] = []
            for event in results {
                let date = CivilDate(event.startsAt, utcOffsetSeconds: formatter.utcOffsetSeconds)
                let key = date.year * 100 + date.month
                if grouped.last?.key == key {
                    grouped[grouped.count - 1].events.append(event)
                } else {
                    grouped.append((key, formatter.monthTitle(year: date.year, month: date.month), [event]))
                }
            }
            sections = grouped.map { group in
                CatalogSnapshot.Section(id: "month-\(group.key)", title: group.title, rows: group.events.map { row($0, formatter, now) })
            }
        } else if results.isEmpty {
            sections = []
        } else {
            sections = [CatalogSnapshot.Section(id: query.sort.rawValue, title: formatter.title(of: query.sort), rows: results.map { row($0, formatter, now) })]
        }

        let chips = [CatalogSnapshot.Chip(id: "all", title: formatter.title(of: nil), count: events.count)]
            + categoryCounts().map { CatalogSnapshot.Chip(id: $0.category.rawValue, title: formatter.title(of: $0.category), count: $0.count) }
        let sorts = EventSort.allCases.map { CatalogSnapshot.Chip(id: $0.rawValue, title: formatter.title(of: $0), count: 0) }

        return CatalogSnapshot(total: events.count, matched: results.count, categories: chips, sorts: sorts, sections: sections)
    }

    private func row(_ event: Event, _ formatter: EventFormatter, _ now: Date) -> CatalogSnapshot.Row {
        CatalogSnapshot.Row(
            id: event.id,
            title: event.title,
            place: event.venue.isEmpty ? event.city : "\(event.venue) · \(event.city)",
            date: formatter.dateLine(event.startsAt),
            countdown: formatter.countdown(to: event.startsAt, now: now),
            price: formatter.price(event.price),
            favorites: formatter.compactCount(event.favorites),
            category: event.category.rawValue,
            categoryTitle: formatter.title(of: event.category),
            organizer: event.organizer,
            summary: event.summary,
            imageURL: event.imageURL
        )
    }
}

/// Display-ready result. Encoded to JSON for Kotlin; usable as-is in SwiftUI.
public struct CatalogSnapshot: Sendable, Codable, Hashable {
    public struct Chip: Sendable, Codable, Hashable {
        public let id: String
        public let title: String
        public let count: Int
    }

    public struct Row: Sendable, Codable, Hashable {
        public let id: String
        public let title: String
        public let place: String
        public let date: String
        public let countdown: String
        public let price: String
        public let favorites: String
        public let category: String
        public let categoryTitle: String
        public let organizer: String
        public let summary: String
        public let imageURL: String?
    }

    public struct Section: Sendable, Codable, Hashable {
        public let id: String
        public let title: String
        public let rows: [Row]
    }

    public let total: Int
    public let matched: Int
    public let categories: [Chip]
    public let sorts: [Chip]
    public let sections: [Section]
}
