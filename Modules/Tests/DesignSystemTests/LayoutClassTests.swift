//
//  LayoutClassTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

@testable import DesignSystem
import SwiftUI
import Testing
import UIKit

struct LayoutClassTests {
    @Test(arguments: [(320.0, LayoutClass.compact), (599, .compact), (600, .medium), (899, .medium), (900, .expanded), (1366, .expanded)])
    func breakpoints(width: Double, expected: LayoutClass) {
        #expect(LayoutClass(width: width) == expected)
    }

    @Test func valuePicksPerClassWithFallback() {
        #expect(LayoutClass.compact.value(compact: 1, medium: 2, expanded: 3) == 1)
        #expect(LayoutClass.medium.value(compact: 1, medium: 2, expanded: 3) == 2)
        #expect(LayoutClass.expanded.value(compact: 1, medium: 2) == 2)
        #expect(LayoutClass.expanded.value(compact: 1) == 1)
        #expect(LayoutClass.compact < .expanded)
        #expect(LayoutClass.compact.pageMargin < LayoutClass.expanded.pageMargin)
    }

    @Test func gridHelpers() {
        #expect([GridItem].columns(3).count == 3)
        #expect([GridItem].columns(0).count == 1)
        #expect([GridItem].adaptive(minWidth: 100).count == 1)
    }

    @Test func colorFromHex() {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(hex: 0xFF8000, alpha: 0.5).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #expect(red == 1)
        #expect(abs(green - 128 / 255) < 0.001)
        #expect(blue == 0)
        #expect(alpha == 0.5)
    }
}
