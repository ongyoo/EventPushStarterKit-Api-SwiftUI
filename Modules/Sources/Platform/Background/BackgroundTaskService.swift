//
//  BackgroundTaskService.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import BackgroundTasks
import Core
import Foundation
import UIKit

/// Identifier of a background task. Must be listed in Info.plist
/// `BGTaskSchedulerPermittedIdentifiers` (Config/Info.plist does it for these two).
public struct BackgroundTaskID: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    /// Custom identifier; must also be in Info.plist `BGTaskSchedulerPermittedIdentifiers`.
    public init(rawValue: String) { self.rawValue = rawValue }

    /// Short refresh (~30s), e.g. fetch new content.
    public static var refresh: Self { Self(rawValue: "\(Bundle.main.bundleIdentifier ?? "app").refresh") }
    /// Long work while charging / idle (minutes), e.g. cleanup, sync, ML.
    public static var processing: Self { Self(rawValue: "\(Bundle.main.bundleIdentifier ?? "app").processing") }
}

/// What the service needs from `BGTaskScheduler` (a protocol so tests can fake it).
public protocol BackgroundTaskScheduling: Sendable {
    func register(identifier: String, handler: @escaping @Sendable (any BackgroundTaskHandle) -> Void) -> Bool
    func submit(_ request: BGTaskRequest) throws
}

/// The running task given by the system (`BGTask`).
public protocol BackgroundTaskHandle: AnyObject {
    var expirationHandler: (() -> Void)? { get set }
    func setTaskCompleted(success: Bool)
}

extension BGTask: BackgroundTaskHandle {}

/// Production scheduler.
public struct SystemBackgroundTaskScheduler: BackgroundTaskScheduling {
    /// The real `BGTaskScheduler`.
    public init() {}

    public func register(identifier: String, handler: @escaping @Sendable (any BackgroundTaskHandle) -> Void) -> Bool {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in handler(task) }
    }

    public func submit(_ request: BGTaskRequest) throws {
        try BGTaskScheduler.shared.submit(request)
    }
}

/// Three kinds of background work:
///
/// 1. **App refresh** (`registerRefresh`) – short periodic update.
/// 2. **Processing** (`registerProcessing`) – long, deferrable work.
/// 3. **Finish what you started** (`runWithExtraTime`) – keep running for a
///    few seconds after the user leaves the app (save, upload...).
///
/// Register in `application(_:didFinishLaunchingWithOptions:)` (before it
/// returns), then call `scheduleAll()` when the app goes to background.
/// Enabled with `FEATURE_BACKGROUND_TASKS = YES`.
///
/// Debug in Xcode (pause the app, then in lldb):
///     e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"<id>"]
@MainActor
public final class BackgroundTaskService {
    public typealias Work = @Sendable () async -> Bool

    private struct Registration {
        let id: BackgroundTaskID
        let work: Work
        let makeRequest: () -> BGTaskRequest
    }

    /// Register in `AppAssembly`, schedule on `sceneDidEnterBackground` (already wired).
    public static let shared = BackgroundTaskService()
    private var registrations: [BackgroundTaskID: Registration] = [:]
    private let permittedIdentifiers: Set<String>
    private let scheduler: any BackgroundTaskScheduling
    /// The system accepts one launch handler per identifier per process.
    private var systemRegistered: Set<BackgroundTaskID> = []

    public init(
        infoDictionary: [String: Any] = Bundle.main.infoDictionary ?? [:],
        scheduler: any BackgroundTaskScheduling = SystemBackgroundTaskScheduler()
    ) {
        permittedIdentifiers = Set(infoDictionary["BGTaskSchedulerPermittedIdentifiers"] as? [String] ?? [])
        self.scheduler = scheduler
    }

    /// - Parameter interval: earliest time before the next run (the system decides the real time).
    public func registerRefresh(_ id: BackgroundTaskID = .refresh, every interval: TimeInterval = 15 * 60, work: @escaping Work) {
        register(id, work: work) {
            let request = BGAppRefreshTaskRequest(identifier: id.rawValue)
            request.earliestBeginDate = Date(timeIntervalSinceNow: interval)
            return request
        }
    }

    /// Long, deferrable work. `work` returns `true` on success.
    ///
    ///     BackgroundTaskService.shared.registerProcessing(requiresNetwork: true) { await sync() }
    public func registerProcessing(
        _ id: BackgroundTaskID = .processing,
        requiresNetwork: Bool = false,
        requiresPower: Bool = true,
        work: @escaping Work
    ) {
        register(id, work: work) {
            let request = BGProcessingTaskRequest(identifier: id.rawValue)
            request.requiresNetworkConnectivity = requiresNetwork
            request.requiresExternalPower = requiresPower
            return request
        }
    }

    /// Submit every registered task. Call on `sceneDidEnterBackground`.
    public func scheduleAll() {
        registrations.values.forEach(schedule)
    }

    /// Identifiers accepted so far.
    public var registeredIDs: Set<BackgroundTaskID> { Set(registrations.keys) }

    /// Keeps the app alive (~30s max) to finish `work` after it goes to background.
    public static func runWithExtraTime(_ name: String, work: @escaping @Sendable () async -> Void) {
        let job = Task { await work() }
        let token = BackgroundTimeToken()
        token.id = UIApplication.shared.beginBackgroundTask(withName: name) {
            // Called on the main thread when time runs out.
            job.cancel()
            MainActor.assumeIsolated { token.end() }
        }
        Task {
            await job.value
            token.end()
        }
    }

    // MARK: - Private

    private func register(_ id: BackgroundTaskID, work: @escaping Work, makeRequest: @escaping () -> BGTaskRequest) {
        // BGTaskScheduler raises an exception (crash) for an identifier missing
        // from Info.plist or registered twice: check both first.
        guard permittedIdentifiers.contains(id.rawValue) else {
            Log.app.fault("Background task \(id.rawValue, privacy: .public) is not in BGTaskSchedulerPermittedIdentifiers: not registered")
            return
        }
        // Latest registration wins: the system handler reads it at launch time.
        registrations[id] = Registration(id: id, work: work, makeRequest: makeRequest)
        guard !systemRegistered.contains(id) else { return }
        systemRegistered.insert(id)
        let accepted = scheduler.register(identifier: id.rawValue) { [weak self] task in
            nonisolated(unsafe) let task = task
            Task { @MainActor in
                guard let self, let work = self.registrations[id]?.work else {
                    task.setTaskCompleted(success: false)
                    return
                }
                Self.run(task, work: work) {
                    Task { @MainActor in self.reschedule(id) }
                }
            }
        }
        if !accepted {
            Log.app.error("Background task \(id.rawValue, privacy: .public) not permitted: add it to BGTaskSchedulerPermittedIdentifiers")
        }
    }

    private func reschedule(_ id: BackgroundTaskID) {
        registrations[id].map(schedule)
    }

    private func schedule(_ registration: Registration) {
        do {
            try scheduler.submit(registration.makeRequest())
        } catch {
            // Expected on the simulator and when Background App Refresh is off.
            Log.app.info("Background task \(registration.id.rawValue, privacy: .public) not scheduled: \(error.localizedDescription, privacy: .public)")
        }
    }

    nonisolated static func run(_ task: any BackgroundTaskHandle, work: @escaping Work, completion: @escaping @Sendable () -> Void) {
        nonisolated(unsafe) let task = task
        let job = Task {
            let success = await work()
            task.setTaskCompleted(success: success && !Task.isCancelled)
            completion()
        }
        task.expirationHandler = { job.cancel() }
    }
}

/// Ends a `beginBackgroundTask` exactly once.
@MainActor
private final class BackgroundTimeToken {
    var id = UIBackgroundTaskIdentifier.invalid

    func end() {
        guard id != .invalid else { return }
        UIApplication.shared.endBackgroundTask(id)
        id = .invalid
    }
}
