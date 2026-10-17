//
//  Typography.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import SwiftUI

/// Text styles built on Dynamic Type, so text scales with user settings.
public extension Font {
    static let dsLargeTitle = Font.system(.largeTitle, weight: .bold)
    static let dsTitle = Font.system(.title2, weight: .bold)
    static let dsHeadline = Font.system(.headline, weight: .semibold)
    static let dsBody = Font.system(.body)
    static let dsCallout = Font.system(.callout)
    static let dsCaption = Font.system(.caption)
}
