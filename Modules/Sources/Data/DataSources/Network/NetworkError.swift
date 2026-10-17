//
//  NetworkError.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation

/// Every networking failure, already mapped to user-facing messages (`localizedDescription`).
public enum NetworkError: Error, Equatable, Sendable {
    case invalidURL
    case noConnection
    case timeout
    case cancelled
    case unauthorized
    case server(statusCode: Int)
    case decoding(String)
    case unknown(String)
}

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid request."
        case .noConnection: "No internet connection."
        case .timeout: "The request timed out."
        case .cancelled: "The request was cancelled."
        case .unauthorized: "Your session has expired. Please sign in again."
        case let .server(code): "Server error (\(code)). Please try again."
        case .decoding: "Unexpected data from server."
        case .unknown: "Something went wrong. Please try again."
        }
    }
}
