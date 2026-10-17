//
//  DynamicScreenPresenter.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Core
import Foundation
import Observation
import ServerDrivenUI

@MainActor
@Observable
final class DynamicScreenPresenter {
    let screenID: String
    private(set) var state: Loadable<DynamicScreen> = .idle
    /// Changes on reload, so the screen's local state starts over.
    private(set) var revision = 0

    @ObservationIgnored private weak var router: (any DynamicScreenRouting)?
    @ObservationIgnored private let interactor: any DynamicScreenInteracting
    @ObservationIgnored private let analytics: any AnalyticsTracking

    init(
        screenID: String,
        interactor: any DynamicScreenInteracting,
        router: (any DynamicScreenRouting)?,
        analytics: any AnalyticsTracking = Container.shared.analytics()
    ) {
        self.screenID = screenID
        self.interactor = interactor
        self.router = router
        self.analytics = analytics
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await interactor.screen(id: screenID))
            revision += 1
        } catch let error as DynamicScreenError {
            state = .failed(Self.message(for: error))
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func loadIfNeeded() async {
        guard case .idle = state else { return }
        await load()
    }

    /// Actions the renderer does not handle itself (state changes stay in the view).
    func perform(_ action: DynamicAction) {
        switch action {
        case let .deepLink(url):
            router?.open(url)
        case let .openURL(url):
            router?.openExternal(url)
        case let .screen(id, presentation):
            router?.showScreen(id: id, presentation: presentation)
        case let .track(event, params):
            analytics.track(AnalyticsEvent(event, params.compactMapValues(Self.analyticsValue)))
        case .dismiss:
            router?.close()
        case .reload:
            Task { await load() }
        case let .sequence(actions):
            actions.forEach(perform)
        case .setState, .toggleState, .custom:
            break
        }
    }

    private static func analyticsValue(_ value: JSONValue) -> AnalyticsValue? {
        switch value {
        case let .string(text): .string(text)
        case let .number(number): number.rounded() == number ? .int(Int(number)) : .double(number)
        case let .bool(flag): .bool(flag)
        default: nil
        }
    }

    private static func message(for error: DynamicScreenError) -> String {
        switch error {
        case .unsupportedSchema, .requiresAppVersion: L10n.tr("dynamic.updateRequired")
        case .invalid: L10n.tr("dynamic.unavailable")
        }
    }
}
