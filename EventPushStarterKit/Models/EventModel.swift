//
//  EventModel.swift
//  EventPush
//
//  Created by Nathat Kuanthanom on 9/3/25.
//

import Foundation

struct Event: Identifiable {
    let id: UUID = UUID()
    let eventId: String
    let title: String
    let description: String
    let priceStartingAt: Double
    let organizerName: String
    let startDate: Date
    let location: Location
    let imageName: String
    let thumbnailUrl: String?
    let category: EventCategory
    let favoriteCount: Int
}

struct EventResponse: Codable {
    let id: String
    let title: String
    let description: String
    let priceStartingAt: Double
    let organizerName: String
    let startDate: String
    let location: Location
    let imageName: String
    let thumbnailUrl: String
    let category: EventCategory
    let favoriteCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case priceStartingAt = "price_starting_at"
        case organizerName = "organizer_name"
        case startDate = "start_date"
        case location
        case imageName = "image_name"
        case thumbnailUrl = "thumbnail_url"
        case category
        case favoriteCount = "favorite_count"
    }
}

extension Event {
    static let sample = Event(
        eventId: "1",
        title: "ฟุตบอลชิงถ้วยพระราชทาน คิงส์คัพ ครั้งที่ 51",
        description:
        """
        🗓️ เปิดขายวันที่ 24 – 26 สิงหาคม 2568
        ⏰ เริ่มเวลา 10.00 น. เป็นต้นไป
        """,
        priceStartingAt: 200.0,
        organizerName: "FA Thailand",
        startDate: Date(),
        location: Location(
            name: "Rajamangala",
            city: "Bangkok",
            latitude: 13.755,
            longitude: 100.622
        ),
        imageName: "event-sample1",
        thumbnailUrl: "",
        category: .sports,
        favoriteCount: 9700
    )
    
    static let samples = [
        Event(
            eventId: "2",
            title: "UEFA Champions League Final 2025",
            description:
            """
            🏆 The biggest club football match in Europe
            🗓️ May 31, 2025
            ⏰ Kick-off 21:00 CET
            ⚽ Watch the best teams compete for glory
            """,
            priceStartingAt: 150.0,
            organizerName: "UEFA",
            startDate: Calendar.current.date(byAdding: .month, value: 8, to: Date()) ?? Date(),
            location: Location(
                name: "Wembley Stadium",
                city: "London",
                latitude: 51.556,
                longitude: -0.280
            ),
            imageName: "event-sample2",
            thumbnailUrl: "",
            category: .sports,
            favoriteCount: 48306
        ),
        
        Event(
            eventId: "3",
            title: "Coachella Valley Music Festival 2025",
            description:
            """
            🎵 World's most famous music festival
            🗓️ April 11-13 & 18-20, 2025
            ⏰ Gates open 11:00 AM daily
            🎤 Top artists from around the globe
            """,
            priceStartingAt: 429.0,
            organizerName: "Goldenvoice",
            startDate: Calendar.current.date(byAdding: .month, value: 7, to: Date()) ?? Date(),
            location: Location(
                name: "Empire Polo Club",
                city: "Indio, California",
                latitude: 33.681,
                longitude: -116.237
            ),
            imageName: "event-sample3",
            thumbnailUrl: "",
            category: .music,
            favoriteCount: 5700
        ),
        
        Event(
            eventId: "4",
            title: "Tokyo Game Show 2025",
            description:
            """
            🎮 Asia's premier gaming exhibition
            🗓️ September 25-28, 2025
            ⏰ 10:00 AM - 5:00 PM
            🕹️ Latest games, tech demos, and esports
            """,
            priceStartingAt: 25.0,
            organizerName: "Computer Entertainment Supplier's Association",
            startDate: Calendar.current.date(byAdding: .month, value: 12, to: Date()) ?? Date(),
            location: Location(
                name: "Makuhari Messe",
                city: "Tokyo",
                latitude: 35.648,
                longitude: 140.035
            ),
            imageName: "event-sample4",
            thumbnailUrl: "",
            category: .entertainment,
            favoriteCount: 4640
        ),
        
        Event(
            eventId: "5",
            title: "Oktoberfest München 2025",
            description:
            """
            🍺 World's largest beer festival
            🗓️ September 20 - October 5, 2025
            ⏰ 10:00 AM - 11:00 PM
            🥨 Traditional Bavarian food and culture
            """,
            priceStartingAt: 0.0,
            organizerName: "City of Munich",
            startDate: Calendar.current.date(byAdding: .month, value: 12, to: Date()) ?? Date(),
            location: Location(
                name: "Theresienwiese",
                city: "Munich",
                latitude: 48.131,
                longitude: 11.550
            ),
            imageName: "event-sample5",
            thumbnailUrl: "",
            category: .community,
            favoriteCount: 3406
        ),
        
        Event(
            eventId: "6",
            title: "Formula 1 Monaco Grand Prix 2025",
            description:
            """
            🏎️ The most prestigious F1 race
            🗓️ May 25, 2025
            ⏰ Race starts 15:00 CET
            🏁 Racing through Monaco's streets
            """,
            priceStartingAt: 220.0,
            organizerName: "Formula 1",
            startDate: Calendar.current.date(byAdding: .month, value: 8, to: Date()) ?? Date(),
            location: Location(
                name: "Circuit de Monaco",
                city: "Monte Carlo",
                latitude: 43.734,
                longitude: 7.420
            ),
            imageName: "event-sample6",
            thumbnailUrl: "",
            category: .sports,
            favoriteCount: 5700
        ),
        
    Event(
        eventId: "7",
        title: "New York Marathon 2025",
        description:
        """
        🏃‍♂️ Annual city marathon
        🗓️ November 2, 2025
        ⏰ Start at 9:00 AM
        🏅 Thousands of runners through NYC
        """,
        priceStartingAt: 120.0,
        organizerName: "NYRR",
        startDate: Calendar.current.date(byAdding: .month, value: 14, to: Date()) ?? Date(),
        location: Location(
            name: "Central Park",
            city: "New York",
            latitude: 40.785,
            longitude: -73.968
        ),
        imageName: "event-sample7",
        thumbnailUrl: "",
        category: .sports,
        favoriteCount: 8900
    ),
    Event(
        eventId: "8",
        title: "Paris Fashion Week Oct 2025",
        description:
        """
        👗 Latest trends from top designers
        🗓️ October 1-8, 2025
        ⏰ Shows start at 2:00 PM daily
        💃 Experience haute couture in Paris
        """,
        priceStartingAt: 500.0,
        organizerName: "Fédération de la Haute Couture",
        startDate: Calendar.current.date(byAdding: .month, value: 13, to: Date()) ?? Date(),
        location: Location(
            name: "Carrousel du Louvre",
            city: "Paris",
            latitude: 48.861,
            longitude: 2.335
        ),
        imageName: "event-sample8",
        thumbnailUrl: "",
        category: .entertainment,
        favoriteCount: 9800
    ),
    Event(
        eventId: "9",
        title: "CES Las Vegas 2026",
        description:
        """
        💡 World's largest tech trade show
        🗓️ January 7-10, 2026
        ⏰ 9:00 AM - 6:00 PM
        📱 Innovations in consumer electronics
        """,
        priceStartingAt: 250.0,
        organizerName: "CTA",
        startDate: Calendar.current.date(byAdding: .month, value: 17, to: Date()) ?? Date(),
        location: Location(
            name: "Las Vegas Convention Center",
            city: "Las Vegas",
            latitude: 36.131,
            longitude: -115.156
        ),
        imageName: "event-sample9",
        thumbnailUrl: "",
        category: .education,
        favoriteCount: 15000
    ),
    Event(
        eventId: "10",
        title: "Tomorrowland Winter 2026",
        description:
        """
        🎧 Epic electronic music festival
        🗓️ March 14-21, 2026
        ⏰ Party from noon till midnight
        ❄️ Dancing in the Alps
        """,
        priceStartingAt: 400.0,
        organizerName: "We Are One World",
        startDate: Calendar.current.date(byAdding: .month, value: 19, to: Date()) ?? Date(),
        location: Location(
            name: "Alpe d'Huez",
            city: "France",
            latitude: 45.090,
            longitude: 6.067
        ),
        imageName: "event-sample10",
        thumbnailUrl: "",
        category: .music,
        favoriteCount: 22000
    ),
    Event(
        eventId: "11",
        title: "Cannes Film Festival 2026",
        description:
        """
        🎥 Prestigious international film festival
        🗓️ May 12-23, 2026
        ⏰ Screenings and premieres daily
        🌟 Red carpet and awards gala
        """,
        priceStartingAt: 350.0,
        organizerName: "Festival de Cannes",
        startDate: Calendar.current.date(byAdding: .month, value: 21, to: Date()) ?? Date(),
        location: Location(
            name: "Palais des Festivals",
            city: "Cannes",
            latitude: 43.552,
            longitude: 7.017
        ),
        imageName: "event-sample11",
        thumbnailUrl: "",
        category: .entertainment,
        favoriteCount: 16000
    ),
    Event(
        eventId: "12",
        title: "Comic-Con San Diego 2026",
        description:
        """
        🎭 Largest pop culture convention
        🗓️ July 23-26, 2026
        ⏰ Panels, exhibits, and cosplay
        📚 Comics, movies, TV & games
        """,
        priceStartingAt: 90.0,
        organizerName: "San Diego Comic-Con",
        startDate: Calendar.current.date(byAdding: .month, value: 23, to: Date()) ?? Date(),
        location: Location(
            name: "San Diego Convention Center",
            city: "San Diego",
            latitude: 32.706,
            longitude: -117.161
        ),
        imageName: "event-sample12",
        thumbnailUrl: "",
        category: .entertainment,
        favoriteCount: 20000
    ),
    Event(
        eventId: "13",
        title: "Rio Carnival 2026",
        description:
        """
        🎉 World’s biggest carnival celebration
        🗓️ February 13-17, 2026
        ⏰ Samba parades and street parties
        🌞 Colorful costumes and music
        """,
        priceStartingAt: 50.0,
        organizerName: "Rio City Council",
        startDate: Calendar.current.date(byAdding: .month, value: 20, to: Date()) ?? Date(),
        location: Location(
            name: "Sambadrome Marquês de Sapucaí",
            city: "Rio de Janeiro",
            latitude: -22.912,
            longitude: -43.230
        ),
        imageName: "event-sample13",
        thumbnailUrl: "",
        category: .community,
        favoriteCount: 30000)]
}
