//
//  Event.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation

/// Domain entity used by the UI. Independent from the API shape (`EventDTO`).
public struct Event: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let description: String
    public let priceStartingAt: Double
    public let organizerName: String
    public let startDate: Date
    public let location: Location
    public let thumbnailURL: URL?
    public let category: EventCategory
    public let favoriteCount: Int

    /// Built from `EventDTO` in production; directly in tests and previews.
    public init(
        id: String,
        title: String,
        description: String,
        priceStartingAt: Double,
        organizerName: String,
        startDate: Date,
        location: Location,
        thumbnailURL: URL?,
        category: EventCategory,
        favoriteCount: Int
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.priceStartingAt = priceStartingAt
        self.organizerName = organizerName
        self.startDate = startDate
        self.location = location
        self.thumbnailURL = thumbnailURL
        self.category = category
        self.favoriteCount = favoriteCount
    }

    /// `true` when the starting price is 0.
    public var isFree: Bool { priceStartingAt == 0 }
}

/// Where an event happens.
public struct Location: Codable, Hashable, Sendable {
    public let name: String
    public let city: String
    public let latitude: Double
    public let longitude: Double

    public init(name: String, city: String, latitude: Double, longitude: Double) {
        self.name = name
        self.city = city
        self.latitude = latitude
        self.longitude = longitude
    }
}
