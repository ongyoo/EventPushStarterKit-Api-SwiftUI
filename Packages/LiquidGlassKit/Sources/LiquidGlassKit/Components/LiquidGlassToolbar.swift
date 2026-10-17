//
//  LiquidGlassToolbar.swift
//  LiquidGlassKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import SwiftUI

/// A floating glass toolbar: icon buttons grouped in one capsule (iOS 26 style).
///
///     LiquidGlassToolbar {
///         LiquidGlassToolbarButton("Share", systemImage: "square.and.arrow.up") { share() }
///         LiquidGlassToolbarButton("Favorite", systemImage: "heart") { like() }
///     }
public struct LiquidGlassToolbar<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        LiquidGlassContainer {
            HStack(spacing: 2) { content }
                .padding(4)
                .liquidGlass(.regular.interactive())
        }
    }
}

/// An icon button for `LiquidGlassToolbar`. `title` is read by VoiceOver.
public struct LiquidGlassToolbarButton: View {
    private let title: String
    private let systemImage: String
    private let isSelected: Bool
    private let action: () -> Void

    public init(_ title: String, systemImage: String, isSelected: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 44, height: 44)
                .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
                .background {
                    if isSelected {
                        Capsule().fill(Color.primary.opacity(0.08))
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(ToolbarPressStyle())
        .accessibilityLabel(Text(title))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct ToolbarPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
