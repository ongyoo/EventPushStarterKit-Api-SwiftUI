//
//  View+DS.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import SwiftUI

public extension View {
    func padding(_ space: DS.Space) -> some View {
        padding(space.rawValue)
    }

    func padding(_ edges: Edge.Set, _ space: DS.Space) -> some View {
        padding(edges, space.rawValue)
    }

    func cornerRadius(_ radius: DS.Radius) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius.rawValue, style: .continuous))
    }

    /// Standard card: background, rounded corners and soft brand shadow.
    func cardStyle(padding space: DS.Space = .s) -> some View {
        self
            .padding(space)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.l.rawValue, style: .continuous)
                    .fill(Color.backgroundPrimary)
                    .shadow(color: .brandSecondary.opacity(0.08), radius: 8, y: 4)
            )
    }
}
