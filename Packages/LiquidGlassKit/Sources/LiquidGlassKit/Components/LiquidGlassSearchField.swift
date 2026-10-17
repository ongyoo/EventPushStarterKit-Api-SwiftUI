//
//  LiquidGlassSearchField.swift
//  LiquidGlassKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import SwiftUI

/// iOS 26-style search field: a glass capsule with a magnifier and a clear
/// button. Native glass on iOS 26, kit glass on iOS 17–18.
///
///     LiquidGlassSearchField(text: $query, prompt: "Search events") { search() }
public struct LiquidGlassSearchField: View {
    @Binding private var text: String
    private let prompt: String
    private let onSubmit: () -> Void
    @FocusState private var isFocused: Bool

    public init(text: Binding<String>, prompt: String, onSubmit: @escaping () -> Void = {}) {
        self._text = text
        self.prompt = prompt
        self.onSubmit = onSubmit
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField(prompt, text: $text)
                .focused($isFocused)
                .submitLabel(.search)
                .onSubmit(onSubmit)
                .textInputAutocapitalization(.never)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Clear"))
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 48)
        .liquidGlass(.regular.interactive())
        .scaleEffect(isFocused ? 1.02 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isFocused)
        .animation(.easeOut(duration: 0.15), value: text.isEmpty)
    }
}
