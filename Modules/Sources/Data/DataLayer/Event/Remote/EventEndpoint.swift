//
//  EventEndpoint.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import DataSources
import Foundation

enum EventEndpoint: Endpoint {
    case list

    var path: String {
        switch self {
        case .list: "event-list/data.json"
        }
    }

    var requiresAuth: Bool { false }
}
