//
//  MockAPIClientTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
@testable import DataSources
import Foundation
import Testing

struct MockAPIClientTests {
    private struct Path: Endpoint {
        let path: String
        var baseURL: URL { URL(string: "https://api.test")! }
    }

    @Test func recordsPathsAndSupportsDelay() async throws {
        let client = MockAPIClient(responses: ["ok": .success(Data("[1]".utf8))], delay: .milliseconds(1))
        try await client.send(Path(path: "ok"))
        let numbers: [Int] = try await client.send(Path(path: "ok"))
        #expect(numbers == [1])
        #expect(client.requestedPaths == ["ok", "ok"])
    }

    @Test func unknownPathIs404AndBadJSONIsDecodingError() async {
        let client = MockAPIClient(responses: ["bad": .success(Data("{".utf8))])
        await #expect(throws: NetworkError.server(statusCode: 404)) { try await client.send(Path(path: "missing")) }
        await #expect {
            let _: [Int] = try await client.send(Path(path: "bad"))
        } throws: { error in
            if case .decoding = error as? NetworkError { return true }
            return false
        }
    }

    @Test func endpointDefaults() throws {
        struct Minimal: Endpoint { var path: String { "x" } }
        let endpoint = Minimal()
        #expect(endpoint.method == .get)
        #expect(endpoint.headers.isEmpty)
        #expect(endpoint.requiresAuth)
        #expect(endpoint.baseURL == Container.shared.appEnvironment().apiBaseURL)

        struct WithHeaders: Endpoint {
            var baseURL: URL { URL(string: "https://api.test")! }
            var path: String { "x" }
            var headers: [String: String] { ["X-Trace": "1"] }
        }
        #expect(try WithHeaders().makeRequest().value(forHTTPHeaderField: "X-Trace") == "1")
    }

    @Test func defaultDependenciesResolve() async {
        let container = Container()
        #expect(container.apiClient() is AlamofireAPIClient)
        #expect(await container.accessTokenProvider().accessToken() == nil)
    }
}

struct PinningTests {
    @Test func clientWithPinnedHostsBuilds() {
        struct NoToken: AccessTokenProvider { func accessToken() async -> String? { nil } }
        _ = AlamofireAPIClient(tokenProvider: NoToken(), pinnedHosts: ["api.example.com"])
    }
}
