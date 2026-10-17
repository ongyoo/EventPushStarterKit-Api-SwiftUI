//
//  AppComponents.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Core
import Domain
import ServerDrivenUI
import SwiftUI

/// The server-driven components of this app: the library's standard set,
/// plus app-specific ones built from the app's own views.
///
/// To add one: register a `type`, document its props for the backend in
/// docs/SERVER_DRIVEN_UI.md, done (no app release needed to *use* it later).
@MainActor
enum AppComponents {
    static let registry: DynamicComponentRegistry = {
        var registry = DynamicComponentRegistry.standard
        // { "type": "event_card", "props": { "eventId": "3" }, "action": {...} }
        registry.register("event_card") { component, context in
            DynamicEventCard(eventID: component.string("eventId") ?? "")
                .onTapGesture { component.action.map(context.perform) }
                .accessibilityAddTraits(component.action == nil ? [] : .isButton)
        }
        return registry
    }()
}

/// Loads an event by id and shows the app's regular event card.
private struct DynamicEventCard: View {
    let eventID: String
    @State private var event: Event?

    var body: some View {
        Group {
            if let event {
                EventCardView(event: event)
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.secondary.opacity(0.12))
                    .frame(height: 180)
            }
        }
        .task(id: eventID) {
            event = try? await Container.shared.eventRepository().event(id: eventID)
        }
    }
}
