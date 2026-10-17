//
//  AlamofireAPIClientTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

@testable import DataSources
import Foundation
import Testing

/// Real `AlamofireAPIClient`, fake network (URLProtocol stub).
@Suite(.serialized)
struct AlamofireAPIClientTests {
    private struct Item: Codable, Sendable, Equatable { let name: String }

    private struct TokenStub: AccessTokenProvider {
        func accessToken() async -> String? { "secret-token" }
    }

    private enum TestEndpoint: Endpoint {
        case privateItem, publicItem

        var baseURL: URL { URL(string: "https://api.test")! }
        var path: String { "item" }
        var requiresAuth: Bool { self == .privateItem }
    }

    private func makeClient() -> AlamofireAPIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return AlamofireAPIClient(tokenProvider: TokenStub(), configuration: configuration)
    }

    @Test func decodesResponseAndSendsBearerToken() async throws {
        StubURLProtocol.respond(status: 200, json: #"{"name":"Ann"}"#)
        let item: Item = try await makeClient().send(TestEndpoint.privateItem)
        #expect(item == Item(name: "Ann"))
        #expect(StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer secret-token")
    }

    @Test func publicEndpointHasNoAuthHeader() async throws {
        StubURLProtocol.respond(status: 204, json: "")
        try await makeClient().send(TestEndpoint.publicItem)
        #expect(StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test func returnsTheRawBody() async throws {
        StubURLProtocol.respond(status: 200, json: #"{"raw":true}"#)
        let data = try await makeClient().data(TestEndpoint.publicItem)
        #expect(String(decoding: data, as: UTF8.self) == #"{"raw":true}"#)
    }

    @Test(arguments: [
        (401, NetworkError.unauthorized),
        (404, .server(statusCode: 404)),
        (500, .server(statusCode: 500)),
    ])
    func mapsHTTPErrors(status: Int, expected: NetworkError) async {
        StubURLProtocol.respond(status: status, json: "{}")
        await #expect(throws: expected) {
            let _: Item = try await makeClient().send(TestEndpoint.publicItem)
        }
    }

    @Test func mapsDecodingError() async {
        StubURLProtocol.respond(status: 200, json: #"{"unexpected":true}"#)
        await #expect {
            let _: Item = try await makeClient().send(TestEndpoint.publicItem)
        } throws: { error in
            if case .decoding = error as? NetworkError { return true }
            return false
        }
    }

    @Test(arguments: [
        (URLError.Code.notConnectedToInternet, NetworkError.noConnection),
        (.timedOut, .timeout),
        (.badServerResponse, .unknown(URLError(.badServerResponse).localizedDescription)),
    ])
    func mapsTransportErrors(code: URLError.Code, expected: NetworkError) async {
        StubURLProtocol.fail(with: URLError(code))
        await #expect(throws: expected) {
            try await makeClient().send(TestEndpoint.publicItem)
        }
    }

    @Test func cancellingTheTaskCancelsTheRequest() async {
        StubURLProtocol.respond(status: 200, json: #"{"name":"Ann"}"#, delay: 1)
        let client = makeClient()
        let task = Task { () -> Item in try await client.send(TestEndpoint.publicItem) }
        try? await Task.sleep(for: .milliseconds(50))
        task.cancel()
        await #expect(throws: NetworkError.cancelled) { try await task.value }
    }

    @Test func errorsHaveUserFacingMessages() {
        let all: [NetworkError] = [.invalidURL, .noConnection, .timeout, .cancelled, .unauthorized,
                                   .server(statusCode: 500), .decoding("x"), .unknown("x")]
        #expect(all.allSatisfy { !($0.errorDescription ?? "").isEmpty })
    }
}

final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    private enum Reply { case success(Int, Data, TimeInterval), failure(any Error) }
    nonisolated(unsafe) private static var reply: Reply = .success(200, Data(), 0)
    nonisolated(unsafe) static var lastRequest: URLRequest?

    static func respond(status: Int, json: String, delay: TimeInterval = 0) {
        reply = .success(status, Data(json.utf8), delay)
    }

    static func fail(with error: any Error) {
        reply = .failure(error)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        switch Self.reply {
        case let .failure(error):
            client?.urlProtocol(self, didFailWithError: error)
        case let .success(status, data, delay):
            if delay > 0 { Thread.sleep(forTimeInterval: delay) }
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}
}
