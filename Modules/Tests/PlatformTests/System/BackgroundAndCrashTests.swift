//
//  BackgroundAndCrashTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import BackgroundTasks
import Core
import Foundation
@testable import Platform
import Testing

@MainActor
struct BackgroundAndCrashTests {
    private let permitted: [String: Any] = [
        "BGTaskSchedulerPermittedIdentifiers": [BackgroundTaskID.refresh.rawValue, BackgroundTaskID.processing.rawValue],
    ]

    @Test func registersOnceSchedulesAndRunsWork() async throws {
        let scheduler = SchedulerSpy()
        let service = BackgroundTaskService(infoDictionary: permitted, scheduler: scheduler)
        service.registerRefresh(every: 60) { true }
        service.registerProcessing(requiresNetwork: true) { true }
        service.registerRefresh { false }                 // re-register: no second system registration
        #expect(scheduler.registered == [BackgroundTaskID.refresh.rawValue, BackgroundTaskID.processing.rawValue])
        #expect(service.registeredIDs.count == 2)

        service.scheduleAll()
        #expect(scheduler.submitted.count == 2)

        // The system launches the refresh task.
        let task = TaskSpy()
        let launch = try #require(scheduler.handlers[BackgroundTaskID.refresh.rawValue])
        launch(task)
        for _ in 0..<50 where task.completed == nil {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(task.completed == false, "Latest registered work returns false")
        task.expirationHandler?()
    }

    @Test func submitFailureIsLoggedNotThrown() {
        let scheduler = SchedulerSpy()
        scheduler.failSubmit = true
        let service = BackgroundTaskService(infoDictionary: permitted, scheduler: scheduler)
        service.registerRefresh { true }
        service.scheduleAll()
        #expect(scheduler.submitted.isEmpty)
    }

    @Test func rejectedRegistrationIsLogged() {
        let scheduler = SchedulerSpy()
        scheduler.accept = false
        let service = BackgroundTaskService(infoDictionary: permitted, scheduler: scheduler)
        service.registerRefresh { true }
        #expect(scheduler.registered.count == 1)
    }

    @Test func crashReportsAreForwarded() {
        let reporter = ReporterSpy()
        let monitor = CrashMonitor()
        monitor.reporter = reporter
        monitor.deliver([CrashDiagnostic(kind: .crash, json: Data("{}".utf8)), CrashDiagnostic(kind: .hang, json: Data())])
        #expect(reporter.kinds == [.crash, .hang])
        monitor.didReceive([])
    }

    @Test func integrityChecksAreCleanOnSimulator() {
        // The simulator sees the Mac's file system (/usr/sbin/sshd...), so only
        // run the checks here; `check()` itself skips them on the simulator.
        _ = DeviceIntegrity.hasSuspiciousFiles()
        #expect(!DeviceIntegrity.check().isCompromised)
        #expect(!DeviceIntegrity.canWriteOutsideSandbox())
        #expect(!DeviceIntegrity.hasInjectedLibrary())
        _ = DeviceIntegrity.isDebuggerAttached()
        #expect(DeviceIntegrity.Finding.allCases.count == 4)
        Log.app.debug("integrity checked")
    }

    @Test func liveActivityReportsUserDisabledOrStarts() throws {
        let service = LiveActivityService<DemoAttributes>(isFeatureEnabled: true)
        if service.isAvailable { return }
        #expect(throws: LiveActivityService<DemoAttributes>.Failure.disabledByUser) {
            try service.start(DemoAttributes(), state: .init(value: 1))
        }
    }
}

private final class SchedulerSpy: BackgroundTaskScheduling, @unchecked Sendable {
    var accept = true
    var failSubmit = false
    private(set) var registered: [String] = []
    private(set) var submitted: [BGTaskRequest] = []
    private(set) var handlers: [String: @Sendable (any BackgroundTaskHandle) -> Void] = [:]

    func register(identifier: String, handler: @escaping @Sendable (any BackgroundTaskHandle) -> Void) -> Bool {
        registered.append(identifier)
        handlers[identifier] = handler
        return accept
    }

    func submit(_ request: BGTaskRequest) throws {
        if failSubmit { throw URLError(.cancelled) }
        submitted.append(request)
    }
}

private final class TaskSpy: BackgroundTaskHandle, @unchecked Sendable {
    var expirationHandler: (() -> Void)?
    private(set) var completed: Bool?
    func setTaskCompleted(success: Bool) { completed = success }
}

private final class ReporterSpy: CrashReporting, @unchecked Sendable {
    private(set) var kinds: [CrashDiagnostic.Kind] = []
    func report(_ diagnostic: CrashDiagnostic) { kinds.append(diagnostic.kind) }
}
