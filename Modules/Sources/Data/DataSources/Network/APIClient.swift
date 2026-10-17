//
//  APIClient.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Foundation

/// The only networking API features and domains see.
/// Swap the implementation (Alamofire, URLSession, mock) without touching callers.
public protocol APIClient: Sendable {
    func send<Response: Decodable & Sendable>(_ endpoint: any Endpoint, as type: Response.Type) async throws -> Response
    func send(_ endpoint: any Endpoint) async throws
    /// The raw response body, for formats decoded elsewhere (server-driven UI screens).
    func data(_ endpoint: any Endpoint) async throws -> Data
}

public extension APIClient {
    func send<Response: Decodable & Sendable>(_ endpoint: any Endpoint) async throws -> Response {
        try await send(endpoint, as: Response.self)
    }
}

/// Supplies the bearer token. Implemented by the auth/session module.
public protocol AccessTokenProvider: Sendable {
    func accessToken() async -> String?
}

public extension Container {
    var apiClient: Dependency<any APIClient> {
        Dependency(self) {
            AlamofireAPIClient(
                tokenProvider: self.accessTokenProvider(),
                pinnedHosts: self.appEnvironment().pinnedHosts
            )
        }.singleton
    }

    /// Default: no token. The auth feature registers its own provider at launch.
    var accessTokenProvider: Dependency<any AccessTokenProvider> {
        Dependency(self) { NoAccessToken() }.singleton
    }
}

struct NoAccessToken: AccessTokenProvider {
    func accessToken() async -> String? { nil }
}
