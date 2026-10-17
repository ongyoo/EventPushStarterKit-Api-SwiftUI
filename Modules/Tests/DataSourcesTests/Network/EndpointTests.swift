//
//  EndpointTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

@testable import DataSources
import Foundation
import Testing

private struct Body: Encodable, Sendable { let name: String }

private enum TestEndpoint: Endpoint {
    case list
    case create(String)

    var baseURL: URL { URL(string: "https://api.example.com/v1")! }

    var path: String {
        switch self {
        case .list: "items"
        case .create: "items"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list: .get
        case .create: .post
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .list: [URLQueryItem(name: "page", value: "2")]
        case .create: []
        }
    }

    var body: (any Encodable & Sendable)? {
        switch self {
        case .list: nil
        case let .create(name): Body(name: name)
        }
    }
}

struct EndpointTests {
    @Test func buildsGetRequestWithQuery() throws {
        let request = try TestEndpoint.list.makeRequest()
        #expect(request.url?.absoluteString == "https://api.example.com/v1/items?page=2")
        #expect(request.httpMethod == "GET")
        #expect(request.httpBody == nil)
    }

    @Test func buildsPostRequestWithJSONBody() throws {
        let request = try TestEndpoint.create("Ann").makeRequest()
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.httpBody == Data(#"{"name":"Ann"}"#.utf8))
    }

    @Test func mockClientDecodesCannedResponse() async throws {
        let client = MockAPIClient(responses: ["items": .success(Data(#"["a","b"]"#.utf8))])
        let items: [String] = try await client.send(TestEndpoint.list)
        #expect(items == ["a", "b"])
    }

    @Test func mockClientPropagatesError() async {
        let client = MockAPIClient(responses: ["items": .failure(.noConnection)])
        await #expect(throws: NetworkError.noConnection) {
            let _: [String] = try await client.send(TestEndpoint.list)
        }
    }
}
