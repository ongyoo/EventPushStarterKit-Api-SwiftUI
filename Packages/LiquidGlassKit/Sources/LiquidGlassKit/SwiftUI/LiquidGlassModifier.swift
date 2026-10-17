//
//  LiquidGlassModifier.swift
//  LiquidGlassKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import SwiftUI

/// The outline of a piece of glass.
public enum LiquidGlassShape: Sendable, Equatable {
    case capsule
    case circle
    case rect(cornerRadius: CGFloat)

    /// `nil` = capsule (also a circle on a square view), as `LiquidGlassView.cornerRadius`.
    var cornerRadius: CGFloat? {
        if case let .rect(radius) = self { return radius }
        return nil
    }

    var shape: AnyShape {
        switch self {
        case .capsule: AnyShape(Capsule())
        case .circle: AnyShape(Circle())
        case let .rect(radius): AnyShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        }
    }
}

/// What kind of glass: like iOS 26's `Glass` (`.regular`, `.clear`, `.tint`, `.interactive`).
public struct LiquidGlassStyle: Sendable, Equatable {
    public var isClear = false
    public var tint: Color?
    /// Reacts to touches (swells, lights up).
    public var isInteractive = false

    public init(isClear: Bool = false, tint: Color? = nil, isInteractive: Bool = false) {
        self.isClear = isClear
        self.tint = tint
        self.isInteractive = isInteractive
    }

    /// Frosted glass.
    public static let regular = LiquidGlassStyle()
    /// See-through glass, for content over media.
    public static let clear = LiquidGlassStyle(isClear: true)

    public func tint(_ color: Color?) -> LiquidGlassStyle {
        var copy = self
        copy.tint = color
        return copy
    }

    public func interactive(_ isOn: Bool = true) -> LiquidGlassStyle {
        var copy = self
        copy.isInteractive = isOn
        return copy
    }

    @available(iOS 26, *)
    var systemGlass: Glass {
        (isClear ? Glass.clear : Glass.regular).tint(tint).interactive(isInteractive)
    }
}

public extension View {
    /// Puts the view on Liquid Glass. iOS 26: Apple's `glassEffect`.
    /// iOS 17–18: the kit's glass (frost, rim light that follows tilt, shadow).
    ///
    ///     Label("Follow", systemImage: "plus")
    ///         .padding(.horizontal, 20).padding(.vertical, 12)
    ///         .liquidGlass()
    ///
    ///     card.liquidGlass(.regular.tint(.purple), in: .rect(cornerRadius: 24))
    func liquidGlass(_ style: LiquidGlassStyle = .regular, in shape: LiquidGlassShape = .capsule) -> some View {
        modifier(LiquidGlassModifier(style: style, shape: shape))
    }

    /// Short form kept for existing code: `.liquidGlass(cornerRadius: 20, tint: .purple)`.
    func liquidGlass(cornerRadius: CGFloat?, tint: UIColor? = nil, isClear: Bool = false) -> some View {
        liquidGlass(
            LiquidGlassStyle(isClear: isClear, tint: tint.map(Color.init(uiColor:))),
            in: cornerRadius.map { .rect(cornerRadius: $0) } ?? .capsule
        )
    }
}

struct LiquidGlassModifier: ViewModifier {
    let style: LiquidGlassStyle
    let shape: LiquidGlassShape
    @State private var isPressed = false

    func body(content: Content) -> some View {
        if LiquidGlass.isSystemDesign, #available(iOS 26, *) {
            content.glassEffect(style.systemGlass, in: shape.shape)
        } else {
            content
                .background(
                    LiquidGlassBackground(
                        cornerRadius: shape.cornerRadius,
                        tint: style.tint.map(UIColor.init),
                        isClear: style.isClear,
                        isPressed: isPressed
                    )
                )
                .simultaneousGesture(pressGesture, including: style.isInteractive ? .all : .subviews)
        }
    }

    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in if !isPressed { isPressed = true } }
            .onEnded { _ in isPressed = false }
    }
}

/// `LiquidGlassView` as a SwiftUI background (kit drawing, any iOS).
struct LiquidGlassBackground: UIViewRepresentable {
    var cornerRadius: CGFloat?
    var tint: UIColor?
    var isClear: Bool
    var isPressed = false

    func makeUIView(context: Context) -> LiquidGlassView {
        let glass = LiquidGlassView()
        glass.effects = [.specular, .motion]
        glass.usesSystemGlass = false // SwiftUI uses `glassEffect` on iOS 26 instead
        glass.isUserInteractionEnabled = false
        return glass
    }

    func updateUIView(_ glass: LiquidGlassView, context: Context) {
        glass.cornerRadius = cornerRadius
        glass.glassTint = tint
        glass.isClear = isClear
        if glass.isPressed != isPressed {
            glass.setPressed(isPressed, at: CGPoint(x: glass.bounds.midX, y: glass.bounds.midY))
        }
    }
}
