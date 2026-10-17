//
//  DeviceIntegrity.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Darwin
import Foundation
import MachO

/// Basic runtime-integrity signals (jailbreak, debugger, hooking tools).
///
/// These checks raise the bar but CAN be bypassed by a determined attacker.
/// Use the result to reduce risk (hide sensitive features, re-authenticate,
/// report to backend), never as the only protection. Real security lives on
/// the server and in the Keychain.
///
///     let report = DeviceIntegrity.check()
///     if report.isCompromised { analytics.track(report.findings) }
public enum DeviceIntegrity {
    /// A single suspicious signal.
    public enum Finding: String, Sendable, CaseIterable {
        case suspiciousFiles
        case writableSystemPath
        case injectedLibrary
        case debuggerAttached
    }

    /// Result of `check()`.
    public struct Report: Sendable {
        public let findings: [Finding]
        /// `true` if any signal was found.
        public var isCompromised: Bool { !findings.isEmpty }
    }

    /// Runs every check (skipped on the simulator, debugger check skipped in Debug).
    public static func check() -> Report {
        #if targetEnvironment(simulator)
        return Report(findings: [])
        #else
        var findings: [Finding] = []
        if hasSuspiciousFiles() { findings.append(.suspiciousFiles) }
        if canWriteOutsideSandbox() { findings.append(.writableSystemPath) }
        if hasInjectedLibrary() { findings.append(.injectedLibrary) }
        #if !DEBUG
        if isDebuggerAttached() { findings.append(.debuggerAttached) }
        #endif
        return Report(findings: findings)
        #endif
    }

    static func hasSuspiciousFiles() -> Bool {
        [
            "/Applications/Cydia.app",
            "/Applications/Sileo.app",
            "/var/jb",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt",
            "/usr/bin/frida-server",
        ].contains { FileManager.default.fileExists(atPath: $0) }
    }

    static func canWriteOutsideSandbox() -> Bool {
        let path = "/private/integrity_check_\(UUID().uuidString)"
        do {
            try "x".write(toFile: path, atomically: true, encoding: .utf8)
            try? FileManager.default.removeItem(atPath: path)
            return true
        } catch {
            return false
        }
    }

    static func hasInjectedLibrary() -> Bool {
        let suspicious = ["substrate", "substitute", "libhooker", "frida", "cycript", "sslkillswitch"]
        for index in 0..<_dyld_image_count() {
            guard let cName = _dyld_get_image_name(index) else { continue }
            let name = String(cString: cName).lowercased()
            if suspicious.contains(where: name.contains) { return true }
        }
        return false
    }

    static func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        guard sysctl(&mib, u_int(mib.count), &info, &size, nil, 0) == 0 else { return false }
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }
}
