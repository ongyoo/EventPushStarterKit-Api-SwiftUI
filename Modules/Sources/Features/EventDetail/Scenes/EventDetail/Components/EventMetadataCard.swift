//
//  EventMetadataCard.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import DesignSystem
import Domain
import SwiftUI

struct EventMetadataCard: View {
    let event: Event

    var body: some View {
        HStack(spacing: 0) {
            EventMetadataItemView(systemImage: "calendar", title: L10n.Event.date, value: event.startDate.monthDayText)
            Divider().padding(.vertical, .xxs)
            EventMetadataItemView(systemImage: "mappin.and.ellipse", title: L10n.Event.location, value: event.location.city)
            Divider().padding(.vertical, .xxs)
            EventMetadataItemView(
                systemImage: "ticket",
                title: L10n.Event.price,
                value: event.isFree ? L10n.Event.free : event.priceStartingAt.currencyText()
            )
        }
        .cardStyle(padding: .m)
    }
}

struct EventMetadataItemView: View {
    let systemImage: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: DS.Space.xxs.rawValue) {
            Label(title, systemImage: systemImage)
                .font(.dsCaption)
                .foregroundStyle(.textSecondary)
            Text(value)
                .font(.dsHeadline)
                .foregroundStyle(.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
