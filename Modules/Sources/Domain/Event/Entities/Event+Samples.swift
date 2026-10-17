//
//  Event+Samples.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation

// Sample data for SwiftUI previews and unit tests only.
public extension Event {
    static let sample = Event(
        id: "1",
        title: "King's Cup 51st Football Championship",
        description: "Ticket sale 24–26 Aug. Gates open 10:00.",
        priceStartingAt: 200,
        organizerName: "FA Thailand",
        startDate: .now.addingTimeInterval(86_400 * 30),
        location: Location(name: "Rajamangala Stadium", city: "Bangkok", latitude: 13.755, longitude: 100.622),
        thumbnailURL: URL(string: "https://picsum.photos/seed/event1/800/600"),
        category: .sports,
        favoriteCount: 9_700
    )

    static let samples: [Event] = [
        sample,
        Event(
            id: "2",
            title: "Coachella Valley Music Festival",
            description: "World's most famous music festival.",
            priceStartingAt: 429,
            organizerName: "Goldenvoice",
            startDate: .now.addingTimeInterval(86_400 * 60),
            location: Location(name: "Empire Polo Club", city: "Indio", latitude: 33.681, longitude: -116.237),
            thumbnailURL: URL(string: "https://picsum.photos/seed/event2/800/600"),
            category: .music,
            favoriteCount: 5_700
        ),
        Event(
            id: "3",
            title: "Tokyo Game Show",
            description: "Asia's premier gaming exhibition.",
            priceStartingAt: 25,
            organizerName: "CESA",
            startDate: .now.addingTimeInterval(86_400 * 90),
            location: Location(name: "Makuhari Messe", city: "Tokyo", latitude: 35.648, longitude: 140.035),
            thumbnailURL: URL(string: "https://picsum.photos/seed/event3/800/600"),
            category: .entertainment,
            favoriteCount: 4_640
        ),
    ]
}
