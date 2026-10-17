//
//  Endpoint.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Foundation

/// HTTP verb of an `Endpoint` (default `.get`).
public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// Describes ONE API call. Each domain declares its endpoints as an enum:
///
///     enum EventEndpoint: Endpoint {
///         case list
///         var path: String { "event-list/data.json" }
///     }
///
/// Only `path` is required; everything else has a sensible default.
public protocol Endpoint: Sendable {
    /// Defaults to `AppEnvironment.apiBaseURL`.
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var queryItems: [URLQueryItem] { get }
    /// Encoded as JSON.
    var body: (any Encodable & Sendable)? { get }
    /// `false` for public endpoints (login, config...) to skip the auth header.
    var requiresAuth: Bool { get }
}

public extension Endpoint {
    var baseURL: URL { Container.shared.appEnvironment().apiBaseURL }
    var method: HTTPMethod { .get }
    var headers: [String: String] { [:] }
    var queryItems: [URLQueryItem] { [] }
    var body: (any Encodable & Sendable)? { nil }
    var requiresAuth: Bool { true }

    func makeRequest(encoder: JSONEncoder = JSONEncoder()) throws -> URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        guard let url = components?.url else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        if let body {
            request.httpBody = try encoder.encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }
}

