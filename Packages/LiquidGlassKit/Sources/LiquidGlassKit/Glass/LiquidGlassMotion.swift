//
//  LiquidGlassMotion.swift
//  LiquidGlassKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import CoreMotion
import UIKit

/// Device tilt for glass highlights (the light on the rim moves when you tilt
/// the phone, like iOS 26). One `CMMotionManager` for the whole app, running
/// only while someone observes, the app is active and Reduce Motion is off.
/// No permission needed (device motion is not activity data).
@MainActor
public final class LiquidGlassMotion {
    public static let shared = LiquidGlassMotion()

    /// Light direction in the view plane (x right, y down), unit length.
    /// Default: light from the top-left, also used when motion is off.
    public private(set) var light = CGVector(dx: -0.45, dy: -0.89)

    private let manager = CMMotionManager()
    private var observers: [UUID: (CGVector) -> Void] = [:]
    private var isActive = true
    private var lifecycle: [NSObjectProtocol] = []

    /// Cancels the observation when released.
    public final class Token {
        fileprivate var cancel: (() -> Void)?
        deinit { cancel?() }
    }

    private init() {
        manager.deviceMotionUpdateInterval = 1 / 30
        let center = NotificationCenter.default
        lifecycle = [
            center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.isActive = true; self?.updateRunning() }
            },
            center.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.isActive = false; self?.updateRunning() }
            },
            center.addObserver(forName: UIAccessibility.reduceMotionStatusDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.updateRunning() }
            },
        ]
    }

    /// `handler` gets the current light at once, then on every change (30 Hz max).
    public func observe(_ handler: @escaping @MainActor (CGVector) -> Void) -> Token {
        let id = UUID()
        observers[id] = handler
        handler(light)
        updateRunning()
        let token = Token()
        token.cancel = { [weak self] in
            MainActor.assumeIsolated {
                self?.observers[id] = nil
                self?.updateRunning()
            }
        }
        return token
    }

    var isRunning: Bool { manager.isDeviceMotionActive }
    var observerCount: Int { observers.count }

    private func updateRunning() {
        let shouldRun = !observers.isEmpty && isActive && !UIAccessibility.isReduceMotionEnabled
            && manager.isDeviceMotionAvailable
        if shouldRun, !manager.isDeviceMotionActive {
            manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
                guard let gravity = motion?.gravity else { return }
                MainActor.assumeIsolated { self?.receive(gravity) }
            }
        } else if !shouldRun, manager.isDeviceMotionActive {
            manager.stopDeviceMotionUpdates()
        }
    }

    /// Gravity -> light coming from "above" the phone, smoothed.
    func receive(_ gravity: CMAcceleration) {
        let target = Self.light(fromGravityX: gravity.x, y: gravity.y)
        // Low-pass filter: highlights glide instead of jittering.
        let smoothed = CGVector(dx: light.dx * 0.8 + target.dx * 0.2, dy: light.dy * 0.8 + target.dy * 0.2)
        let length = max(hypot(smoothed.dx, smoothed.dy), 0.001)
        let next = CGVector(dx: smoothed.dx / length, dy: smoothed.dy / length)
        guard abs(next.dx - light.dx) + abs(next.dy - light.dy) > 0.004 else { return }
        light = next
        observers.values.forEach { $0(next) }
    }

    /// Phone upright (gravity y = -1): light from the top. Tilt right: light moves left.
    static func light(fromGravityX x: Double, y: Double) -> CGVector {
        let dx = CGFloat(-x) - 0.35
        let dy = CGFloat(y) * 0.9 - 0.1
        let length = max(hypot(dx, dy), 0.001)
        return CGVector(dx: dx / length, dy: dy / length)
    }
}
