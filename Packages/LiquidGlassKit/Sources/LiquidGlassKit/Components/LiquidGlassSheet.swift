//
//  LiquidGlassSheet.swift
//  LiquidGlassKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import SwiftUI

public extension View {
    /// Glass background for a sheet's content (apply inside `.sheet { }`).
    /// iOS 26 sheets are already glass: nothing changes there.
    /// iOS 17–18: frosted glass with rim light and larger rounded corners.
    ///
    ///     .sheet(isPresented: $showFilters) {
    ///         FiltersView().presentationDetents([.medium, .large]).liquidGlassSheet()
    ///     }
    @ViewBuilder
    func liquidGlassSheet() -> some View {
        if LiquidGlass.isSystemDesign {
            self
        } else {
            presentationBackground {
                LiquidGlassBackground(cornerRadius: 0, tint: nil, isClear: false)
                    .ignoresSafeArea()
            }
            .presentationCornerRadius(34)
        }
    }
}
