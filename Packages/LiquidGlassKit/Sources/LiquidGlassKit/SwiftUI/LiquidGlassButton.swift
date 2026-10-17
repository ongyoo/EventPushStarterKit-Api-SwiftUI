//
//  LiquidGlassButton.swift
//  LiquidGlassKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import SwiftUI

/// Glass button look: `.regular` (clear glass, tinted label) or `.prominent`
/// (accent-filled glass, white label), like iOS 26's `.glass` / `.glassProminent`.
public enum LiquidGlassButtonKind: Sendable, Equatable {
    case regular
    case prominent
}

public extension View {
    /// Glass button style. iOS 26: Apple's `.glass` / `.glassProminent`.
    /// iOS 17–18: `LiquidGlassButtonStyle`.
    ///
    ///     Button("Buy ticket") { ... }.liquidGlassButton(.prominent)
    ///     Button { ... } label: { Image(systemName: "heart") }.liquidGlassButton()
    @ViewBuilder
    func liquidGlassButton(_ kind: LiquidGlassButtonKind = .regular) -> some View {
        if LiquidGlass.isSystemDesign, #available(iOS 26, *) {
            switch kind {
            case .regular: buttonStyle(.glass)
            case .prominent: buttonStyle(.glassProminent)
            }
        } else {
            buttonStyle(LiquidGlassButtonStyle(kind: kind))
        }
    }
}

/// The kit's glass button (iOS 17+). Prefer `.liquidGlassButton()`, which
/// switches to the system style on iOS 26.
public struct LiquidGlassButtonStyle: ButtonStyle {
    public var kind: LiquidGlassButtonKind
    @Environment(\.isEnabled) private var isEnabled

    public init(kind: LiquidGlassButtonKind = .regular) {
        self.kind = kind
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .frame(minHeight: 44)
            .foregroundStyle(kind == .prominent ? AnyShapeStyle(Color.white) : AnyShapeStyle(.tint))
            .background {
                if kind == .prominent {
                    // `.tint` follows the view's tint (not only the app accent color).
                    ZStack {
                        Capsule().fill(.tint)
                        LiquidGlassBackground(cornerRadius: nil, tint: nil, isClear: true, isPressed: configuration.isPressed)
                    }
                } else {
                    LiquidGlassBackground(cornerRadius: nil, tint: nil, isClear: false, isPressed: configuration.isPressed)
                }
            }
            .contentShape(Capsule())
            .opacity(isEnabled ? 1 : 0.45)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
