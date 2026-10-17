//
//  TaskBag.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation

/// Cancels its tasks when it is deallocated (like Combine's `AnyCancellable`).
/// Gives UIKit presenters / view controllers SwiftUI's `.task {}` behaviour:
/// work stops automatically when the screen goes away.
///
///     private let tasks = TaskBag()
///
///     Task { [weak self] in
///         let items = try await interactor.fetch()
///         self?.show(items)
///     }
///     .store(in: tasks)
public final class TaskBag: @unchecked Sendable {
    private let lock = NSLock()
    private var cancellers: [@Sendable () -> Void] = []

    /// Create one per presenter / view controller: `private let tasks = TaskBag()`.
    public init() {}

    /// Cancels every stored task now (e.g. before starting a new load).
    public func cancelAll() {
        let current = lock.withLock {
            defer { cancellers.removeAll() }
            return cancellers
        }
        current.forEach { $0() }
    }

    fileprivate func insert(_ cancel: @escaping @Sendable () -> Void) {
        lock.withLock { cancellers.append(cancel) }
    }

    deinit {
        cancellers.forEach { $0() }
    }
}

public extension Task {
    /// Ties the task's lifetime to `bag`.
    @discardableResult
    func store(in bag: TaskBag) -> Self {
        bag.insert { self.cancel() }
        return self
    }
}
