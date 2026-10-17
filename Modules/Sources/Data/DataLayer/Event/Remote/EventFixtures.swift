//
//  EventFixtures.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation

/// Offline JSON responses for this domain. Used by the app's Mock API mode
/// (`USE_MOCK_API = YES` in Debug.xcconfig) and by unit tests.
public enum EventFixtures {
    /// `[endpoint path: response JSON]`, ready for `MockAPIClient`.
    public static var responses: [String: Data] {
        guard let url = Bundle.module.url(forResource: "events", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [:] }
        return [EventEndpoint.list.path: data]
    }
}
