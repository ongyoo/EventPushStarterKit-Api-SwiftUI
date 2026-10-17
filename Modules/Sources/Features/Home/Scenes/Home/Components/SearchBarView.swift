//
//  SearchBarView.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import DesignSystem
import SwiftUI

struct SearchBarView: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: DS.Space.s.rawValue) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.textSecondary)
            TextField(L10n.Home.search, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.textTertiary)
                }
                .accessibilityLabel(L10n.Home.clearSearch)
            }
        }
        .padding(.s)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.m.rawValue)
                .fill(Color.backgroundPrimary)
                .strokeBorder(Color.divider)
        )
    }
}
