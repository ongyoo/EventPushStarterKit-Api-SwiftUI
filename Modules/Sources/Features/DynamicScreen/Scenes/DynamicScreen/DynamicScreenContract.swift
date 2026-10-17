//
//  DynamicScreenContract.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Foundation
import ServerDrivenUI

// MARK: - Router (implemented by DynamicScreenCoordinator)

@MainActor
protocol DynamicScreenRouting: AnyObject {
    /// In-app deep link, or an external page if it is not one.
    func open(_ url: URL)
    func openExternal(_ url: URL)
    func showScreen(id: String, presentation: DynamicAction.Presentation)
    func close()
}

// MARK: - Interactor

protocol DynamicScreenInteracting: Sendable {
    /// Fetches and decodes the screen (falls back to cache / bundled copy).
    func screen(id: String) async throws -> DynamicScreen
}
