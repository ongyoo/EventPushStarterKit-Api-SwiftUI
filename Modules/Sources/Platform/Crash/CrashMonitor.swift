//
//  CrashMonitor.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Foundation
import MetricKit

/// Where crash / hang reports go. Plug Crashlytics, Sentry or your backend
/// here later without touching the rest of the app.
public protocol CrashReporting: Sendable {
    func report(_ diagnostic: CrashDiagnostic)
}

/// One MetricKit report.
public struct CrashDiagnostic: Sendable {
    /// Type of report.
    public enum Kind: String, Sendable { case crash, hang, cpuException, diskWriteException }
    public let kind: Kind
    /// Full MetricKit JSON (call stacks, OS version, app version...).
    public let json: Data
}

/// Crash & hang monitoring with Apple's MetricKit: no third-party SDK,
/// no app size cost. iOS delivers the previous session's diagnostics
/// (at most once a day in production, immediately in TestFlight/debug via
/// Xcode > Debug > Simulate MetricKit Payloads).
@MainActor
public final class CrashMonitor: NSObject {
    /// Started by `AppAssembly`.
    public static let shared = CrashMonitor()

    /// Where reports are sent; `nil` = only logged.
    public var reporter: (any CrashReporting)?
    private var isStarted = false

    /// Subscribes to MetricKit once: `CrashMonitor.shared.start(reporter: MyReporter())`.
    public func start(reporter: (any CrashReporting)? = nil) {
        if let reporter { self.reporter = reporter }
        guard !isStarted else { return }
        isStarted = true
        MXMetricManager.shared.add(self)
    }

    nonisolated func diagnostics(from payload: MXDiagnosticPayload) -> [CrashDiagnostic] {
        var result: [CrashDiagnostic] = []
        payload.crashDiagnostics?.forEach { result.append(CrashDiagnostic(kind: .crash, json: $0.jsonRepresentation())) }
        payload.hangDiagnostics?.forEach { result.append(CrashDiagnostic(kind: .hang, json: $0.jsonRepresentation())) }
        payload.cpuExceptionDiagnostics?.forEach { result.append(CrashDiagnostic(kind: .cpuException, json: $0.jsonRepresentation())) }
        payload.diskWriteExceptionDiagnostics?.forEach { result.append(CrashDiagnostic(kind: .diskWriteException, json: $0.jsonRepresentation())) }
        return result
    }
}

extension CrashMonitor: MXMetricManagerSubscriber {
    public nonisolated func didReceive(_ payloads: [MXDiagnosticPayload]) {
        let diagnostics = payloads.flatMap(diagnostics(from:))
        Task { @MainActor in deliver(diagnostics) }
    }

    func deliver(_ diagnostics: [CrashDiagnostic]) {
        for diagnostic in diagnostics {
            Log.app.fault("MetricKit \(diagnostic.kind.rawValue, privacy: .public) report received")
            reporter?.report(diagnostic)
        }
    }
}
