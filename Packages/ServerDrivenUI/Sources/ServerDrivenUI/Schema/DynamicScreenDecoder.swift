//
//  DynamicScreenDecoder.swift
//  ServerDrivenUI
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Foundation

/// Why a screen cannot be shown. The app shows a fallback (cached screen,
/// bundled screen, or "update the app").
public enum DynamicScreenError: Error, Equatable, Sendable {
    /// The backend sent a newer format than this app understands.
    case unsupportedSchema(version: Int)
    /// The screen needs a newer app (`minAppVersion`).
    case requiresAppVersion(String)
    /// Not valid JSON / missing required fields.
    case invalid(String)
}

/// JSON -> `DynamicScreen`, with version checks.
public enum DynamicScreenDecoder {
    /// Highest `schemaVersion` this build renders. Bump when the format
    /// changes in a non-compatible way; additive changes keep it.
    public static let supportedSchemaVersion = 1

    public static func decode(_ data: Data, appVersion: String) throws -> DynamicScreen {
        let screen: DynamicScreen
        do {
            screen = try JSONDecoder().decode(DynamicScreen.self, from: data)
        } catch {
            throw DynamicScreenError.invalid(String(describing: error))
        }
        guard screen.schemaVersion <= supportedSchemaVersion else {
            throw DynamicScreenError.unsupportedSchema(version: screen.schemaVersion)
        }
        if let minimum = screen.minAppVersion, isVersion(appVersion, olderThan: minimum) {
            throw DynamicScreenError.requiresAppVersion(minimum)
        }
        return screen
    }

    /// `"1.9.2"` < `"1.10"`: numeric, part by part.
    static func isVersion(_ version: String, olderThan minimum: String) -> Bool {
        let lhs = version.split(separator: ".").map { Int($0) ?? 0 }
        let rhs = minimum.split(separator: ".").map { Int($0) ?? 0 }
        for index in 0..<max(lhs.count, rhs.count) {
            let a = index < lhs.count ? lhs[index] : 0
            let b = index < rhs.count ? rhs[index] : 0
            if a != b { return a < b }
        }
        return false
    }
}
