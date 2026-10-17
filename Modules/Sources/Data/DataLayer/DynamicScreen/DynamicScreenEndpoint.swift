//
//  DynamicScreenEndpoint.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Core
import DataSources
import Foundation

/// `GET bff/screens/<id>?schema=1&lang=th`. The BFF answers in the app's
/// language and in a schema version this build understands.
enum DynamicScreenEndpoint: Endpoint {
    case screen(id: String, schemaVersion: Int, language: String)

    var path: String {
        switch self {
        case let .screen(id, _, _): "bff/screens/\(id)"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case let .screen(_, schemaVersion, language):
            [URLQueryItem(name: "schema", value: String(schemaVersion)), URLQueryItem(name: "lang", value: language)]
        }
    }

    var requiresAuth: Bool { false }
}
