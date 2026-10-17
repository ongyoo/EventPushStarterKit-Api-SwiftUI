//
//  LiquidGlassSegmentedPicker.swift
//  LiquidGlassKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import SwiftUI

/// Segmented control on glass, with a glass drop that slides (and stretches)
/// to the chosen segment. iOS 26 shows the system segmented `Picker`.
///
///     LiquidGlassSegmentedPicker(selection: $filter, segments: [
///         .init("All", value: Filter.all),
///         .init("Music", value: Filter.music, systemImage: "music.note"),
///     ])
public struct LiquidGlassSegmentedPicker<Value: Hashable>: View {
    public struct Segment: Identifiable {
        public let title: String
        public let value: Value
        public let systemImage: String?
        public var id: Value { value }

        public init(_ title: String, value: Value, systemImage: String? = nil) {
            self.title = title
            self.value = value
            self.systemImage = systemImage
        }
    }

    @Binding private var selection: Value
    private let segments: [Segment]
    @Namespace private var drop

    public init(selection: Binding<Value>, segments: [Segment]) {
        self._selection = selection
        self.segments = segments
    }

    public var body: some View {
        if LiquidGlass.isSystemDesign {
            Picker("", selection: $selection) {
                ForEach(segments) { segment in
                    Text(segment.title).tag(segment.value)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        } else {
            kitPicker
        }
    }

    private var kitPicker: some View {
        HStack(spacing: 0) {
            ForEach(segments) { segment in
                let isSelected = segment.value == selection
                Button {
                    selection = segment.value
                } label: {
                    Label {
                        Text(segment.title)
                    } icon: {
                        if let systemImage = segment.systemImage { Image(systemName: systemImage) }
                    }
                    .labelStyle(.titleAndIcon)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
                    .frame(maxWidth: .infinity, minHeight: 36)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(Color(uiColor: .tertiarySystemBackground).opacity(0.9))
                                .shadow(color: .black.opacity(0.1), radius: 4, y: 1)
                                .matchedGeometryEffect(id: "drop", in: drop)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(3)
        .liquidGlass()
        .animation(.spring(response: 0.38, dampingFraction: 0.72), value: selection)
    }
}
