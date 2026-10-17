//
//  MockAPIClient.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation

/// Returns canned JSON per endpoint path. For unit tests and previews.
///
///     let client = MockAPIClient(responses: ["event-list/data.json": jsonData])
public final class MockAPIClient: APIClient, @unchecked Sendable {
    private let responses: [String: Result<Data, NetworkError>]
    private let delay: Duration
    public private(set) var requestedPaths: [String] = []

    /// - Parameters:
    ///   - responses: `[endpoint path: JSON data or error]`.
    ///   - delay: simulated latency.
    public init(responses: [String: Result<Data, NetworkError>] = [:], delay: Duration = .zero) {
        self.responses = responses
        self.delay = delay
    }

    public func send<Response: Decodable & Sendable>(_ endpoint: any Endpoint, as type: Response.Type) async throws -> Response {
        let data = try await respond(to: endpoint)
        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw NetworkError.decoding(String(describing: error))
        }
    }

    public func send(_ endpoint: any Endpoint) async throws {
        _ = try await respond(to: endpoint)
    }

    public func data(_ endpoint: any Endpoint) async throws -> Data {
        try await respond(to: endpoint)
    }

    private func respond(to endpoint: any Endpoint) async throws -> Data {
        requestedPaths.append(endpoint.path)
        if delay > .zero { try await Task.sleep(for: delay) }
        guard let result = responses[endpoint.path] else { throw NetworkError.server(statusCode: 404) }
        return try result.get()
    }
}
