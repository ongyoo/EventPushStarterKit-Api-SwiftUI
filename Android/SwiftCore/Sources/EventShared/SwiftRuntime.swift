//
//  SwiftRuntime.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//


/// Where this code is running. Shown in the Android demo to prove the
/// business logic is the same compiled Swift.
public enum SwiftRuntime {
    /// e.g. "Swift 6.4 · Android · arm64"
    public static var summary: String {
        "Swift \(compilerVersion) · \(operatingSystem) · \(architecture)"
    }

    public static var compilerVersion: String {
        #if compiler(>=6.5)
        "6.5+"
        #elseif compiler(>=6.4)
        "6.4"
        #elseif compiler(>=6.3)
        "6.3"
        #elseif compiler(>=6.2)
        "6.2"
        #else
        "6.x"
        #endif
    }

    public static var operatingSystem: String {
        #if os(Android)
        "Android"
        #elseif os(iOS)
        "iOS"
        #elseif os(macOS)
        "macOS"
        #elseif os(Linux)
        "Linux"
        #else
        "Unknown OS"
        #endif
    }

    public static var architecture: String {
        #if arch(arm64)
        "arm64"
        #elseif arch(x86_64)
        "x86_64"
        #elseif arch(arm)
        "armv7"
        #else
        "unknown"
        #endif
    }
}
