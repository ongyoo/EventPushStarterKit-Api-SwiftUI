//
//  Colors.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import SwiftUI
import UIKit

// Single source for brand colors. SwiftUI `Color` and UIKit `UIColor`
// share the same values so mixed SwiftUI / Storyboard screens look identical.
public extension UIColor {
    static let brandPrimary = UIColor(hex: 0x7952FC)
    static let brandSecondary = UIColor(hex: 0xB15CDE)

    static let textPrimary = UIColor.label
    static let textSecondary = UIColor(hex: 0x7A7A90)
    static let textTertiary = UIColor(hex: 0xB4B4C1)

    static let backgroundPrimary = UIColor.systemBackground
    static let backgroundSecondary = UIColor.secondarySystemBackground
    static let backgroundHighlight = UIColor(hex: 0xEDE8FD)

    static let border = UIColor(hex: 0xD5D5DD)
    static let divider = UIColor(hex: 0xE0E0E6)
    static let skeleton = UIColor.systemGray5

    /// `UIColor(hex: 0x7952FC)` or with alpha `UIColor(hex: 0x7952FC, alpha: 0.5)`.
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

public extension Color {
    static let brandPrimary = Color(uiColor: .brandPrimary)
    static let brandSecondary = Color(uiColor: .brandSecondary)

    static let textPrimary = Color(uiColor: .textPrimary)
    static let textSecondary = Color(uiColor: .textSecondary)
    static let textTertiary = Color(uiColor: .textTertiary)

    static let backgroundPrimary = Color(uiColor: .backgroundPrimary)
    static let backgroundSecondary = Color(uiColor: .backgroundSecondary)
    static let backgroundHighlight = Color(uiColor: .backgroundHighlight)

    static let border = Color(uiColor: .border)
    static let divider = Color(uiColor: .divider)
    static let skeleton = Color(uiColor: .skeleton)
}

public extension ShapeStyle where Self == Color {
    static var brandPrimary: Color { .brandPrimary }
    static var brandSecondary: Color { .brandSecondary }
    static var textPrimary: Color { .textPrimary }
    static var textSecondary: Color { .textSecondary }
    static var textTertiary: Color { .textTertiary }
    static var backgroundPrimary: Color { .backgroundPrimary }
    static var backgroundSecondary: Color { .backgroundSecondary }
    static var border: Color { .border }
    static var divider: Color { .divider }
    static var skeleton: Color { .skeleton }
}

public extension LinearGradient {
    static let brand = LinearGradient(
        colors: [.brandPrimary, .brandSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
