//
//  HomeHeaderView.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import DesignSystem
import SwiftUI

struct HomeHeaderView: View {
    let city: String
    let onNotificationsTap: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DS.Space.xxs.rawValue) {
                Text(L10n.Home.location)
                    .font(.dsCaption)
                    .foregroundStyle(.textSecondary)
                Label(city, systemImage: "mappin.circle.fill")
                    .font(.dsHeadline)
                    .foregroundStyle(.textPrimary)
            }
            Spacer()
            Button(action: onNotificationsTap) {
                Image(systemName: "bell.fill")
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(LinearGradient.brand))
            }
            .accessibilityLabel(L10n.Home.notifications)
        }
    }
}
