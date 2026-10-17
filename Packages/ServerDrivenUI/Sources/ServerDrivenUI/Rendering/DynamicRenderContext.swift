//
//  DynamicRenderContext.swift
//  ServerDrivenUI
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Observation
import os
import SwiftUI

/// Values of one screen (`state` in the JSON), changed by `setState` actions
/// and by bound controls (`bind`). Views showing them update at once.
@MainActor
@Observable
public final class DynamicScreenState {
    public private(set) var values: [String: JSONValue]

    public init(_ values: [String: JSONValue] = [:]) {
        self.values = values
    }

    public subscript(key: String) -> JSONValue? {
        get { values[key] }
        set { values[key] = newValue }
    }

    /// `"Hello {{name}}"` -> `"Hello Ann"` with `state.name = "Ann"`.
    public func interpolate(_ text: String) -> String {
        guard text.contains("{{") else { return text }
        var result = text
        for (key, value) in values {
            result = result.replacingOccurrences(of: "{{\(key)}}", with: value.string ?? "")
        }
        return result
    }
}

/// Everything a component renderer needs.
@MainActor
public struct DynamicRenderContext {
    public let state: DynamicScreenState
    public let registry: DynamicComponentRegistry
    /// Runs an action: state actions here, the rest by the app's handler.
    public let perform: (DynamicAction) -> Void

    /// Renders child components (for containers).
    public func render(_ components: [DynamicComponent]) -> some View {
        ForEach(components) { component in
            DynamicComponentView(component: component, context: self)
        }
    }

    /// Two-way binding to `state[key]` for controls.
    public func binding(_ key: String?, default fallback: JSONValue) -> Binding<JSONValue> {
        Binding(
            get: { key.flatMap { state[$0] } ?? fallback },
            set: { newValue in if let key { state[key] = newValue } }
        )
    }
}

/// Renders one component: registry lookup, `visibleIf`, unknown types skipped.
public struct DynamicComponentView: View {
    let component: DynamicComponent
    let context: DynamicRenderContext

    public init(component: DynamicComponent, context: DynamicRenderContext) {
        self.component = component
        self.context = context
    }

    public var body: some View {
        if component.visibleIf?.isSatisfied(by: context.state.values) ?? true {
            if let render = context.registry.renderer(for: component.type) {
                render(component, context)
            } else {
                // Newer backend, older app: skip what this build does not know.
                let _ = DynamicLog.logger.notice("Unknown component type: \(component.type, privacy: .public)")
            }
        }
    }
}

enum DynamicLog {
    static let logger = Logger(subsystem: "ServerDrivenUI", category: "render")
}
