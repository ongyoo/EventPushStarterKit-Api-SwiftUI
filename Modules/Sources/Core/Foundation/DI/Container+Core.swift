//
//  Container+Core.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation

public extension Container {
    /// Runtime configuration read from Info.plist (base URL, deep link scheme...).
    var appEnvironment: Dependency<AppEnvironment> {
        Dependency(self) { AppEnvironment.current }.singleton
    }
}
