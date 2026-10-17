//
//  LiveActivityService.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import ActivityKit
import Core
import Foundation

/// Start / update / end Live Activities for one `ActivityAttributes` type.
/// The UI lives in a Widget Extension (Templates/Extensions/LiveActivity).
///
///     let service = LiveActivityService<EventActivityAttributes>()
///     let id = try service.start(attributes, state: .init(status: "Gates open"))
///     await service.update(id, state: .init(status: "Kick-off"))
///     await service.end(id)
///
/// Enabled with `FEATURE_LIVE_ACTIVITIES = YES` (adds `NSSupportsLiveActivities`).
/// Stateless and `Sendable`: call it from any actor.
public final class LiveActivityService<Attributes: ActivityAttributes>: Sendable {
    /// Why `start` refused.
    public enum Failure: Error, Equatable {
        case disabledByApp
        case disabledByUser
    }

    private let isFeatureEnabled: Bool

    /// Reads `FEATURE_LIVE_ACTIVITIES` by default.
    public init(isFeatureEnabled: Bool = AppEnvironment.current.features.liveActivities) {
        self.isFeatureEnabled = isFeatureEnabled
    }

    /// Feature on AND the user allows Live Activities for the app.
    public var isAvailable: Bool {
        isFeatureEnabled && ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// IDs of running activities of this type.
    public var activeIDs: [String] {
        Activity<Attributes>.activities.map(\.id)
    }

    /// - Parameter pushUpdates: `true` to update it from your server via APNs
    ///   (send the activity's push token to your backend).
    @discardableResult
    public func start(
        _ attributes: Attributes,
        state: Attributes.ContentState,
        staleDate: Date? = nil,
        pushUpdates: Bool = false
    ) throws -> String {
        guard isFeatureEnabled else { throw Failure.disabledByApp }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { throw Failure.disabledByUser }
        let activity = try Activity.request(
            attributes: attributes,
            content: ActivityContent(state: state, staleDate: staleDate),
            pushType: pushUpdates ? .token : nil
        )
        return activity.id
    }

    /// New state (and optional alert sound/banner) for a running activity.
    public func update(_ id: String, state: Attributes.ContentState, alert: AlertConfiguration? = nil) async {
        guard let activity = activity(id) else { return }
        await activity.update(ActivityContent(state: state, staleDate: nil), alertConfiguration: alert)
    }

    /// Ends one activity, optionally showing `finalState` until `dismissal`.
    public func end(_ id: String, finalState: Attributes.ContentState? = nil, dismissal: ActivityUIDismissalPolicy = .default) async {
        guard let activity = activity(id) else { return }
        await activity.end(finalState.map { ActivityContent(state: $0, staleDate: nil) }, dismissalPolicy: dismissal)
    }

    /// Ends every activity of this type immediately (e.g. on logout).
    public func endAll() async {
        for activity in Activity<Attributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private func activity(_ id: String) -> Activity<Attributes>? {
        Activity<Attributes>.activities.first { $0.id == id }
    }
}
