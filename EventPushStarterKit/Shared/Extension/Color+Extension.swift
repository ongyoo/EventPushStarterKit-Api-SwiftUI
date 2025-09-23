//
//  Color+Extension.swift
//  EventPush
//
//  Created by Nathat Kuanthanom on 9/2/25.
//

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b, a: UInt64
        switch hex.count {
        case 3: // RGB (12-bit, e.g. FFF)
            (r, g, b, a) = (
                (int >> 8) * 17,
                (int >> 4 & 0xF) * 17,
                (int & 0xF) * 17,
                255
            )
        case 6: // RGB (24-bit, e.g. FF0000)
            (r, g, b, a) = (
                int >> 16,
                int >> 8 & 0xFF,
                int & 0xFF,
                255
            )
        case 8: // ARGB (32-bit, e.g. FF0000FF)
            (r, g, b, a) = (
                int >> 24,
                int >> 16 & 0xFF,
                int >> 8 & 0xFF,
                int & 0xFF
            )
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension Color {
    static let brandPrimary = Color(hex: "#7952FC")
    static let brandSecondary = Color(hex: "#B15CDE")
    
    static let textPrimary = Color.black
    static let textSecondary = Color(hex: "#7A7A90")
    static let textTertiary = Color(hex: "#B4B4C1")
    
    static let backgroundPrimary = Color.white
    static let backgroundSecondary = Color(hex: "#FAFAFA")
    static let backgroundHighlight = Color(hex: "#EDE8FD")

    static let border = Color(hex: "#D5D5DD")
    static let divider = Color(hex: "#E0E0E6")

    static let gradientPurple = [Color.brandPrimary, Color.brandSecondary]
}
