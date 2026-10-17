//
//  LeakDetector.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation

/// Debug-only helper that warns when an object outlives its expected lifetime.
///
/// Call it at the moment an object *should* be released, e.g. when a
/// coordinator finishes or a screen is popped:
///
///     LeakDetector.expectDeallocation(of: childCoordinator)
///
/// If the object is still alive after `delay`, a fault is logged
/// (and, if `assertsOnLeak` is on, the debugger stops).
/// Compiles to nothing in Release builds.
public enum LeakDetector {
    /// Turn off to silence leak checks (e.g. in UI tests).
    @MainActor public static var isEnabled = true
    @MainActor public static var assertsOnLeak = false

    @MainActor
    public static func expectDeallocation(
        of object: AnyObject?,
        after delay: Duration = .seconds(2),
        file: StaticString = #fileID,
        line: UInt = #line
    ) {
        #if DEBUG
        guard isEnabled, let object else { return }
        let name = String(describing: type(of: object))
        let reference = WeakReference(object)

        Task { @MainActor in
            try? await Task.sleep(for: delay)
            guard reference.value != nil else { return }
            Log.memory.fault("Possible leak: \(name) is still alive \(delay) after release (\(file):\(line))")
            if assertsOnLeak {
                assertionFailure("Possible leak: \(name)")
            }
        }
        #endif
    }
}

/// Holds an object without retaining it.
public final class WeakReference<T: AnyObject>: @unchecked Sendable {
    public private(set) weak var value: T?
    /// Wraps `value` without retaining it: `WeakReference(controller).value`.
    public init(_ value: T) { self.value = value }
}
