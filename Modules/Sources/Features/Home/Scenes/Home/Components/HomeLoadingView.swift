//
//  HomeLoadingView.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import DesignSystem
import SwiftUI

/// Skeleton built from the real components + sample data,
/// so it always matches the loaded layout.
struct HomeLoadingView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.m.rawValue) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Space.m.rawValue) {
                    ForEach(0..<2, id: \.self) { _ in EventCardView(event: .sample) }
                }
                .pageMargin()
            }
            .scrollDisabled(true)
            VStack(spacing: DS.Space.s.rawValue) {
                ForEach(0..<3, id: \.self) { _ in EventRowView(event: .sample) }
            }
            .pageMargin()
        }
        .skeleton()
    }
}
