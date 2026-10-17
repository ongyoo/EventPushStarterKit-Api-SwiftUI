//
//  EventDTO.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Domain
import Foundation

/// API response shape. Kept internal: only `Event` leaves this module.
struct EventDTO: Decodable, Sendable {
    let id: String
    let title: String
    let description: String
    let priceStartingAt: Double
    let organizerName: String
    let startDate: String
    let location: Location
    let thumbnailUrl: String?
    let category: EventCategory
    let favoriteCount: Int

    enum CodingKeys: String, CodingKey {
        case id, title, description, location, category
        case priceStartingAt = "price_starting_at"
        case organizerName = "organizer_name"
        case startDate = "start_date"
        case thumbnailUrl = "thumbnail_url"
        case favoriteCount = "favorite_count"
    }

    func toDomain() -> Event {
        Event(
            id: id,
            title: title,
            description: description,
            priceStartingAt: priceStartingAt,
            organizerName: organizerName,
            startDate: Date(iso8601: startDate) ?? .now,
            location: location,
            thumbnailURL: thumbnailUrl.flatMap(URL.init(string:)),
            category: category,
            favoriteCount: favoriteCount
        )
    }
}
