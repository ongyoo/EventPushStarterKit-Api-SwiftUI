//
//  EventCarousel.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import DesignSystem
import Domain
import SwiftUI

/// Horizontal list of large cards.
///
/// Put it in a regular `VStack`, not directly in a `LazyVStack`: a lazy stack
/// destroys it when it scrolls off screen and the horizontal position is lost.
struct EventCarousel: View {
    let events: [Event]
    var animated = true
    let onSelect: (Event) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: DS.Space.m.rawValue) {
                ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                    Button { onSelect(event) } label: {
                        EventCardView(event: event)
                            // Start point of the hero transition into the detail page.
                            .transitionSource(id: HeroID.event(event.id))
                    }
                    .buttonStyle(.pressable)
                    .staggeredAppear(index: index, style: .slideFromTrailing, isEnabled: animated)
                }
            }
            // Cards are the snap targets of `.viewAligned` (required, or snapping is ignored).
            .scrollTargetLayout()
            .pageMargin()
        }
        .scrollTargetBehavior(.viewAligned)
    }
}

/// One visual row of the upcoming list: 1 event on iPhone, 2–3 side by side
/// on wider screens.
struct EventRowGroup: Identifiable {
    let events: [Event]
    var id: String { "row." + (events.first?.id ?? "") }

    static func make(_ events: [Event], columns: Int) -> [EventRowGroup] {
        let size = max(columns, 1)
        return stride(from: 0, to: events.count, by: size).map { start in
            EventRowGroup(events: Array(events[start..<min(start + size, events.count)]))
        }
    }
}

struct EventRowGroupView: View {
    let group: EventRowGroup
    let columns: Int
    let onSelect: (Event) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: DS.Space.m.rawValue) {
            ForEach(group.events) { event in
                Button { onSelect(event) } label: { EventRowView(event: event) }
                    .buttonStyle(.pressable)
                    .frame(maxWidth: .infinity)
            }
            // Keep equal widths on the last, incomplete row.
            ForEach(0..<max(columns - group.events.count, 0), id: \.self) { _ in
                Color.clear.frame(maxWidth: .infinity)
            }
        }
    }
}
