//
//  Networker.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 23/9/2568 BE.
//

import Foundation

enum HTTPMethod: String {
    case GET, POST
}

enum NetworkError: Error {
    case invalidURL
    case requestFailed
    case decodingFailed
}

struct Networker {
    static func request<T: Decodable>(
        url: String,
        method: HTTPMethod = .GET,
        body: Encodable? = nil
    ) async -> Result<T, NetworkError> {
        guard let url = URL(string: url) else { return .failure(.invalidURL) }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = body {
            let encoder = JSONEncoder()
            do {
                request.httpBody = try encoder.encode(AnyEncodable(body))
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                return .failure(.requestFailed)
            }
        }

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(T.self, from: data)
            return .success(decoded)
        } catch is DecodingError {
            return .failure(.decodingFailed)
        } catch {
            return .failure(.requestFailed)
        }
    }
}

struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init(_ encodable: Encodable) { self._encode = encodable.encode }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}

// MARK: - Usage Example
/*
Task {
    let result: Result<User, NetworkError> = await Networker.request(url: "https://jsonplaceholder.typicode.com/users/1")
    switch result {
    case .success(let user): print("User:", user)
    case .failure(let error): print("Error:", error)
    }
}
*/
