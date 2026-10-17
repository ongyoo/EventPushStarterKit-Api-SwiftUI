//
//  Event.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//


#if canImport(FoundationEssentials)
import FoundationEssentials // Android / Linux: no ICU, keeps the .so small
#else
import Foundation
#endif

/// An event, decoded straight from the API / fixture JSON.
/// The same type works on iOS, macOS and Android.
public struct Event: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let summary: String
    public let price: Double
    public let organizer: String
    public let startsAt: Date
    public let venue: String
    public let city: String
    public let category: EventCategory
    public let favorites: Int
    public let imageURL: String?

    public init(
        id: String, title: String, summary: String = "", price: Double, organizer: String = "",
        startsAt: Date, venue: String = "", city: String, category: EventCategory,
        favorites: Int = 0, imageURL: String? = nil
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.price = price
        self.organizer = organizer
        self.startsAt = startsAt
        self.venue = venue
        self.city = city
        self.category = category
        self.favorites = favorites
        self.imageURL = imageURL
    }

    /// `true` when the starting price is 0.
    public var isFree: Bool { price == 0 }
}

/// Event type. Unknown API values become `.other` instead of failing the response.
public enum EventCategory: String, CaseIterable, Sendable, Codable {
    case sports, entertainment, education, music, community, other

    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = EventCategory(rawValue: raw) ?? .other
    }
}

extension Event: Decodable {
    private enum CodingKeys: String, CodingKey {
        case id, title, description, category, location
        case price = "price_starting_at"
        case organizer = "organizer_name"
        case startsAt = "start_date"
        case favorites = "favorite_count"
        case imageURL = "thumbnail_url"
    }

    private struct Location: Decodable {
        let name: String
        let city: String
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let location = try container.decode(Location.self, forKey: .location)
        self.init(
            id: try container.decode(String.self, forKey: .id),
            title: try container.decode(String.self, forKey: .title),
            summary: try container.decodeIfPresent(String.self, forKey: .description) ?? "",
            price: try container.decodeIfPresent(Double.self, forKey: .price) ?? 0,
            organizer: try container.decodeIfPresent(String.self, forKey: .organizer) ?? "",
            startsAt: try container.decode(Date.self, forKey: .startsAt),
            venue: location.name,
            city: location.city,
            category: try container.decodeIfPresent(EventCategory.self, forKey: .category) ?? .other,
            favorites: try container.decodeIfPresent(Int.self, forKey: .favorites) ?? 0,
            imageURL: try container.decodeIfPresent(String.self, forKey: .imageURL)
        )
    }
}
