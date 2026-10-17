//
//  LiquidGlassToggle.swift
//  LiquidGlassKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import SwiftUI

public extension View {
    /// iOS 26 switch: while touched, the knob stretches and turns to glass.
    /// iOS 26 uses the system switch (already glass); iOS 17–18 `LiquidGlassToggleStyle`.
    ///
    ///     Toggle("Notifications", isOn: $isOn).liquidGlassToggle()
    @ViewBuilder
    func liquidGlassToggle() -> some View {
        if LiquidGlass.isSystemDesign {
            toggleStyle(.switch)
        } else {
            toggleStyle(LiquidGlassToggleStyle())
        }
    }
}

/// The kit's switch for iOS 17–18. Prefer `.liquidGlassToggle()`.
public struct LiquidGlassToggleStyle: ToggleStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        LiquidGlassSwitch(configuration: configuration)
    }
}

private struct LiquidGlassSwitch: View {
    let configuration: ToggleStyleConfiguration
    @GestureState private var isTouching = false
    @Environment(\.isEnabled) private var isEnabled

    private let trackSize = CGSize(width: 54, height: 32)

    var body: some View {
        HStack {
            configuration.label
            Spacer(minLength: 8)
            track
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text(configuration.isOn ? "On" : "Off"))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { configuration.isOn.toggle() }
    }

    private var track: some View {
        let isOn = configuration.isOn
        let knobWidth: CGFloat = isTouching ? 38 : 28
        return ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? AnyShapeStyle(.tint) : AnyShapeStyle(Color(uiColor: .systemFill)))
            Capsule()
                .fill(isTouching ? AnyShapeStyle(.clear) : AnyShapeStyle(Color.white))
                .frame(width: knobWidth, height: isTouching ? 26 : 28)
                .liquidGlass(isTouching ? .clear : .regular, in: .capsule)
                .shadow(color: .black.opacity(isTouching ? 0.08 : 0.2), radius: 3, y: 1)
                .scaleEffect(isTouching ? 1.2 : 1)
                .padding(2)
        }
        .frame(width: trackSize.width, height: trackSize.height)
        .opacity(isEnabled ? 1 : 0.45)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isTouching)
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($isTouching) { _, state, _ in state = true }
                .onEnded { value in
                    // Tap toggles; a swipe goes to the side it ends on.
                    if abs(value.translation.width) < 8 {
                        configuration.isOn.toggle()
                    } else {
                        configuration.isOn = value.translation.width > 0
                    }
                }
        )
    }
}
