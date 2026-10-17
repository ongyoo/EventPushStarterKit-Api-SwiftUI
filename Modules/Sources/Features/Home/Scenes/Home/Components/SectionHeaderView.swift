//
//  SectionHeaderView.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import DesignSystem
import SwiftUI

struct SectionHeaderView: View {
    let title: String
    let onSeeAll: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.dsTitle)
                .foregroundStyle(.textPrimary)
            Spacer()
            Button(L10n.Home.seeAll, action: onSeeAll)
                .font(.dsCallout)
                .foregroundStyle(.brandPrimary)
        }
    }
}
