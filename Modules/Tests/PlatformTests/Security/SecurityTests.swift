//
//  SecurityTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

@testable import Platform
import Testing

@MainActor
struct SecurityTests {
    @Test func deviceSecurityChecksRunOnSimulator() {
        #expect(!DeviceIntegrity.check().isCompromised)
        _ = BiometricAuthenticator().availableKind
    }
}
