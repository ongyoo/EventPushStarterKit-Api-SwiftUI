//
//  AdaptiveLayout.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import SwiftUI

/// Width-based layout class. Works for iPhone, iPad, Split View,
/// Stage Manager and rotation (it measures the real container width,
/// not the device model).
///
/// | Class      | Width        | Typical                         |
/// |------------|--------------|---------------------------------|
/// | `compact`  | < 600 pt     | iPhone portrait, iPad 1/3 split |
/// | `medium`   | 600..<900 pt | iPhone landscape, iPad portrait |
/// | `expanded` | >= 900 pt    | iPad landscape, Mac             |
public enum LayoutClass: Int, Comparable, Sendable {
    case compact, medium, expanded

    /// Class for a container width in points.
    public init(width: CGFloat) {
        switch width {
        case ..<600: self = .compact
        case ..<900: self = .medium
        default: self = .expanded
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    /// Pick a value per layout class:
    ///
    ///     let columns = layout.value(compact: 1, medium: 2, expanded: 3)
    public func value<T>(compact: T, medium: T? = nil, expanded: T? = nil) -> T {
        switch self {
        case .compact: compact
        case .medium: medium ?? compact
        case .expanded: expanded ?? medium ?? compact
        }
    }

    /// Horizontal page margin that grows on bigger screens.
    public var pageMargin: CGFloat {
        value(compact: DS.Space.m.rawValue, medium: DS.Space.xl.rawValue, expanded: DS.Space.xxl.rawValue)
    }
}

private struct LayoutClassKey: EnvironmentKey {
    static let defaultValue: LayoutClass = .compact
}

public extension EnvironmentValues {
    var layoutClass: LayoutClass {
        get { self[LayoutClassKey.self] }
        set { self[LayoutClassKey.self] = newValue }
    }
}

public extension View {
    /// Apply ONCE at the root of a screen. Measures the width and publishes
    /// `\.layoutClass` to every child view:
    ///
    ///     @Environment(\.layoutClass) private var layout
    func adaptiveLayout() -> some View {
        modifier(AdaptiveLayoutModifier())
    }

    /// Caps content width and centers it (readable lines on iPad).
    func readableWidth(_ maxWidth: CGFloat = DS.Size.readableWidth) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }

    /// Page margin that adapts to the layout class.
    func pageMargin() -> some View {
        modifier(PageMarginModifier())
    }
}

private struct AdaptiveLayoutModifier: ViewModifier {
    @State private var layoutClass: LayoutClass = .compact

    func body(content: Content) -> some View {
        content
            .environment(\.layoutClass, layoutClass)
            .onGeometryChange(for: LayoutClass.self) { proxy in
                LayoutClass(width: proxy.size.width)
            } action: { newValue in
                layoutClass = newValue
            }
    }
}

private struct PageMarginModifier: ViewModifier {
    @Environment(\.layoutClass) private var layout

    func body(content: Content) -> some View {
        content.padding(.horizontal, layout.pageMargin)
    }
}

/// Vertical on compact, horizontal on wider layouts.
///
///     AdaptiveStack { Poster(); Details() }
public struct AdaptiveStack<Content: View>: View {
    @Environment(\.layoutClass) private var layout
    private let threshold: LayoutClass
    private let spacing: CGFloat
    private let content: Content

    public init(
        horizontalFrom threshold: LayoutClass = .medium,
        spacing: DS.Space = .m,
        @ViewBuilder content: () -> Content
    ) {
        self.threshold = threshold
        self.spacing = spacing.rawValue
        self.content = content()
    }

    public var body: some View {
        let stack = layout >= threshold
            ? AnyLayout(HStackLayout(alignment: .top, spacing: spacing))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: spacing))
        stack { content }
    }
}

public extension Array where Element == GridItem {
    /// Columns that fill the width with items of at least `minWidth`:
    ///
    ///     LazyVGrid(columns: .adaptive(minWidth: 160)) { ... }
    static func adaptive(minWidth: CGFloat, spacing: DS.Space = .m) -> [GridItem] {
        [GridItem(.adaptive(minimum: minWidth), spacing: spacing.rawValue)]
    }

    /// Fixed number of equal columns, usually from the layout class:
    ///
    ///     LazyVGrid(columns: .columns(layout.value(compact: 1, medium: 2, expanded: 3)))
    static func columns(_ count: Int, spacing: DS.Space = .m) -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing.rawValue), count: Swift.max(count, 1))
    }
}
