//
//  OrganizerRowView.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import DesignSystem
import Domain
import SwiftUI

struct OrganizerRowView: View {
    let name: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Space.s.rawValue) {
                Text(String(name.prefix(1)))
                    .font(.dsHeadline)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(LinearGradient.brand))
                VStack(alignment: .leading) {
                    Text(name)
                        .font(.dsHeadline)
                        .foregroundStyle(.textPrimary)
                    Text(L10n.Event.organizer)
                        .font(.dsCaption)
                        .foregroundStyle(.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.textTertiary)
            }
            .cardStyle()
        }
        .buttonStyle(.pressable)
    }
}

struct AboutSectionView: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs.rawValue) {
            Text(L10n.Event.about)
                .font(.dsTitle)
            Text(text)
                .font(.dsBody)
                .foregroundStyle(.textSecondary)
        }
    }
}
