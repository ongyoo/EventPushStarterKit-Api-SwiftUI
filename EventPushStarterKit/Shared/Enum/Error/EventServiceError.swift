//
//  EventServiceError.swift
//  EventPush
//
//  Created by Nathat Kuanthanom on 9/10/25.
//

import Foundation

enum EventServiceError: Error {
    case networkError
    case mockFailure
}

extension EventServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Unable to fetch events due to a network issue."
        case .mockFailure:
            return "Mock service failed intentionally for testing."
        }
    }
}
