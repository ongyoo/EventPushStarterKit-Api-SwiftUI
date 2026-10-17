//
//  AlamofireAPIClient.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Alamofire
import Core
import Foundation

/// `APIClient` backed by Alamofire. Alamofire stays an implementation detail:
/// nothing outside this file imports it.
public final class AlamofireAPIClient: APIClient {
    private let session: Session
    private let tokenProvider: any AccessTokenProvider
    private let decoder: JSONDecoder

    /// - Parameter pinnedHosts: hosts whose TLS public key must match a
    ///   certificate (`.cer`) bundled in the app (SSL pinning). Empty = off.
    ///   Always bundle the current AND the next certificate before rotating.
    public init(
        tokenProvider: any AccessTokenProvider,
        pinnedHosts: [String] = [],
        decoder: JSONDecoder = JSONDecoder(),
        timeout: TimeInterval = 30,
        configuration: URLSessionConfiguration = .af.default
    ) {
        configuration.timeoutIntervalForRequest = timeout
        configuration.waitsForConnectivity = false

        #if DEBUG
        let monitors: [any EventMonitor] = [NetworkLogger()]
        #else
        let monitors: [any EventMonitor] = []
        #endif

        let trustManager: ServerTrustManager? = pinnedHosts.isEmpty ? nil : ServerTrustManager(
            evaluators: Dictionary(uniqueKeysWithValues: pinnedHosts.map { host in
                (host, PublicKeysTrustEvaluator(keys: Bundle.main.af.publicKeys) as any ServerTrustEvaluating)
            })
        )

        self.session = Session(
            configuration: configuration,
            serverTrustManager: trustManager,
            eventMonitors: monitors
        )
        self.tokenProvider = tokenProvider
        self.decoder = decoder
    }

    public func send<Response: Decodable & Sendable>(
        _ endpoint: any Endpoint,
        as type: Response.Type
    ) async throws -> Response {
        let request = try await authorizedRequest(for: endpoint)
        let task = session.request(request)
            .validate()
            .serializingDecodable(Response.self, decoder: decoder)

        return try await withTaskCancellationHandler {
            try await Self.map(task.response)
        } onCancel: {
            task.cancel()
        }
    }

    public func send(_ endpoint: any Endpoint) async throws {
        let request = try await authorizedRequest(for: endpoint)
        let task = session.request(request)
            .validate()
            .serializingData(emptyResponseCodes: [200, 201, 202, 204])

        _ = try await withTaskCancellationHandler {
            try await Self.map(task.response)
        } onCancel: {
            task.cancel()
        }
    }

    public func data(_ endpoint: any Endpoint) async throws -> Data {
        let request = try await authorizedRequest(for: endpoint)
        let task = session.request(request).validate().serializingData()
        return try await withTaskCancellationHandler {
            try await Self.map(task.response)
        } onCancel: {
            task.cancel()
        }
    }

    private func authorizedRequest(for endpoint: any Endpoint) async throws -> URLRequest {
        var request = try endpoint.makeRequest()
        if endpoint.requiresAuth, let token = await tokenProvider.accessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private static func map<Value>(_ response: DataResponse<Value, AFError>) throws -> Value {
        switch response.result {
        case let .success(value):
            return value
        case let .failure(error):
            throw NetworkError(error, statusCode: response.response?.statusCode)
        }
    }
}

extension NetworkError {
    init(_ error: AFError, statusCode: Int?) {
        if error.isExplicitlyCancelledError {
            self = .cancelled
            return
        }
        if let urlError = error.underlyingError as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                self = .noConnection
            case .timedOut:
                self = .timeout
            case .cancelled:
                self = .cancelled
            default:
                self = .unknown(urlError.localizedDescription)
            }
            return
        }
        if case .responseSerializationFailed = error {
            self = .decoding(error.localizedDescription)
            return
        }
        switch statusCode {
        case 401?: self = .unauthorized
        case let code? where code >= 400: self = .server(statusCode: code)
        default: self = .unknown(error.localizedDescription)
        }
    }
}

#if DEBUG
/// Logs every request/response in Debug builds only.
final class NetworkLogger: EventMonitor, @unchecked Sendable {
    let queue = DispatchQueue(label: "network.logger", qos: .utility)

    func request<Value>(_ request: DataRequest, didParseResponse response: DataResponse<Value, AFError>) {
        let method = request.request?.httpMethod ?? "-"
        let url = request.request?.url?.absoluteString ?? "-"
        let status = response.response?.statusCode ?? 0
        let duration = String(format: "%.0fms", (response.metrics?.taskInterval.duration ?? 0) * 1000)
        Log.network.debug("\(method) \(url) -> \(status) (\(duration))")
    }
}
#endif
