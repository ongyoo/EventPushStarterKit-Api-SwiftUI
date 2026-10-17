//
//  EventRowView.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import DesignSystem
import Domain
import SwiftUI

/// Compact row: thumbnail + title + date + location.
struct EventRowView: View {
    private let event: Event

    init(event: Event) {
        self.event = event
    }

    var body: some View {
        HStack(spacing: DS.Space.s.rawValue) {
            RemoteImage(url: event.thumbnailURL)
                .frame(width: 80, height: 80)
                .cornerRadius(.s)

            VStack(alignment: .leading, spacing: DS.Space.xxs.rawValue) {
                Text(event.title)
                    .font(.dsHeadline)
                    .foregroundStyle(.textPrimary)
                    .lineLimit(2)
                Label(event.startDate.relativeText, systemImage: "calendar")
                    .font(.dsCaption)
                    .foregroundStyle(.textSecondary)
                Label(event.location.city, systemImage: "mappin.and.ellipse")
                    .font(.dsCaption)
                    .foregroundStyle(.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack {
        EventRowView(event: .sample)
        EventRowView(event: .sample).skeleton()
    }
    .padding()
}
