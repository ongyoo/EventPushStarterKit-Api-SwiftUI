//
//  NavigationDemoView.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import DesignSystem
import SwiftUI

/// Tiny screen used to try navigation styles and transitions.
/// Actions are closures from the coordinator (captured weakly there).
struct NavigationDemoView: View {
    struct Action: Identifiable {
        let id = UUID()
        let title: String
        let run: () -> Void
    }

    let title: String
    let actions: [Action]

    var body: some View {
        VStack(spacing: DS.Space.l.rawValue) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 64))
                .foregroundStyle(LinearGradient.brand)
                .floating()
            Text(title)
                .font(.dsTitle)
            ForEach(actions) { action in
                Button(action.title, action: action.run)
                    .buttonStyle(.borderedProminent)
                    .tint(.brandPrimary)
            }
        }
        .padding(.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundSecondary)
    }
}

#Preview {
    NavigationDemoView(title: "Screen 1", actions: [.init(title: "Close") {}])
}
