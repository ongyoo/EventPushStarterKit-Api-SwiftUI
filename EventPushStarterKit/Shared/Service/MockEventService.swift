//
//  MockEventService.swift
//  EventPush
//
//  Created by Nathat Kuanthanom on 9/10/25.
//

import Foundation

class MockEventService: EventServiceProtocol {
    func fetchEvents() async throws -> [Event] {
        try await Task.sleep(for: .seconds(1))
        throw EventServiceError.mockFailure
    }
}
