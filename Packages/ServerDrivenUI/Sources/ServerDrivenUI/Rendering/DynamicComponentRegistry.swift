//
//  DynamicComponentRegistry.swift
//  ServerDrivenUI
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import SwiftUI

/// Maps a JSON `type` to a SwiftUI view. Start from `.standard` and add your
/// own components (e.g. an `event_card` that uses your app's design):
///
///     var registry = DynamicComponentRegistry.standard
///     registry.register("event_card") { component, context in
///         EventCard(id: component.string("eventId") ?? "")
///             .onTapGesture { component.action.map(context.perform) }
///     }
///
/// Registering an existing type replaces the built-in look.
public struct DynamicComponentRegistry {
    public typealias Renderer = @MainActor (DynamicComponent, DynamicRenderContext) -> AnyView

    private var renderers: [String: Renderer] = [:]

    public init() {}

    public mutating func register<Content: View>(
        _ type: String,
        @ViewBuilder _ render: @escaping @MainActor (DynamicComponent, DynamicRenderContext) -> Content
    ) {
        renderers[type] = { component, context in AnyView(render(component, context)) }
    }

    public func renderer(for type: String) -> Renderer? {
        renderers[type]
    }

    /// Types this registry can draw (send them to the BFF as "capabilities").
    public var supportedTypes: [String] {
        renderers.keys.sorted()
    }
}
