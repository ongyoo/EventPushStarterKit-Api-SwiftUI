//
//  EventService.swift
//  EventPush
//
//  Created by Nathat Kuanthanom on 9/10/25.
//

import Foundation

protocol EventServiceProtocol {
    func fetchEvents() async throws -> [Event]
}

final class EventService: EventServiceProtocol {
    func fetchEvents() async throws -> [Event] {
        let url = "https://pub-f0bfae22754e4aa4a1ee891e99b27472.r2.dev/api/event-list/data.json"
        let result: Result<[EventResponse], NetworkError> = await Networker.request(url: url)
        switch result {
        case .success(let events):
            return events.compactMap { respone -> Event in
                return Event(eventId: respone.id,
                             title: respone.title,
                             description: respone.description,
                             priceStartingAt: respone.priceStartingAt,
                             organizerName: respone.organizerName,
                             startDate: respone.startDate.toDateISO8601() ?? Date(),
                             location: respone.location,
                             imageName: respone.imageName,
                             thumbnailUrl: respone.thumbnailUrl,
                             category: respone.category,
                             favoriteCount: respone.favoriteCount)
            }
        case .failure(let error):
            throw error
        }
    }
}
