//
//  EventLiveActivity.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

// Widget Extension source for the "event day" Live Activity.
//
// Setup (once, ~2 minutes) – see docs/CAPABILITIES.md:
// 1. Xcode > File > New > Target > Widget Extension, name "EventWidgets",
//    tick "Include Live Activity", untick "Include Configuration App Intent".
// 2. Replace the generated Live Activity file with this one.
// 3. EventWidgets target > General > Frameworks: add the `Domain` product (Modules package).
// 4. Config/Features.xcconfig: FEATURE_LIVE_ACTIVITIES = YES, then Clean Build Folder.

import ActivityKit
import Domain
import SwiftUI
import WidgetKit

struct EventLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EventActivityAttributes.self) { context in
            // Lock screen / banner
            HStack(spacing: 12) {
                Image(systemName: "ticket.fill")
                    .font(.title2)
                    .foregroundStyle(.purple)
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.title).font(.headline).lineLimit(1)
                    Text(context.attributes.venue).font(.caption).foregroundStyle(.secondary)
                    Text(context.state.status).font(.subheadline)
                }
                Spacer()
                Text(context.state.startsAt, style: .timer)
                    .font(.title3.monospacedDigit())
                    .frame(width: 80)
            }
            .padding()
            .activityBackgroundTint(Color(.systemBackground))
            .widgetURL(URL(string: "eventpush://events/\(context.attributes.eventID)"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "ticket.fill").foregroundStyle(.purple)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.startsAt, style: .timer).monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("\(context.attributes.title) · \(context.state.status)").lineLimit(1)
                }
            } compactLeading: {
                Image(systemName: "ticket.fill").foregroundStyle(.purple)
            } compactTrailing: {
                Text(context.state.startsAt, style: .timer).monospacedDigit().frame(width: 44)
            } minimal: {
                Image(systemName: "ticket.fill").foregroundStyle(.purple)
            }
            .widgetURL(URL(string: "eventpush://events/\(context.attributes.eventID)"))
        }
    }
}
