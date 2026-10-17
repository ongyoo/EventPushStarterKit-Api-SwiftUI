//
//  EventCardView.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import DesignSystem
import Domain
import SwiftUI

/// Large image card with a date badge. Used in carousels.
struct EventCardView: View {
    private let event: Event

    init(event: Event) {
        self.event = event
    }

    var body: some View {
        RemoteImage(url: event.thumbnailURL)
            .frame(width: 267, height: 184)
            .cornerRadius(.m)
            .overlay(alignment: .topLeading) {
                DateBadge(date: event.startDate)
                    .padding(.xs)
            }
            .overlay(alignment: .bottomLeading) {
                Text(event.title)
                    .font(.dsHeadline)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .padding(.s)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                    .cornerRadius(.m)
            }
            .accessibilityElement(children: .combine)
    }
}

/// "SEP / 30" badge.
struct DateBadge: View {
    private let date: Date

    init(date: Date) {
        self.date = date
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(date.monthText.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.brandPrimary)
            Text(date.dayText)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.textPrimary)
        }
        .frame(width: 40, height: 40)
        .background(RoundedRectangle(cornerRadius: DS.Radius.s.rawValue).fill(Color.backgroundPrimary))
    }
}

#Preview {
    EventCardView(event: .sample)
}
