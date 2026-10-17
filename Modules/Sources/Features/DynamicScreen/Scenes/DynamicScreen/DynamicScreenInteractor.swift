//
//  DynamicScreenInteractor.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Core
import Domain
import Foundation
import ServerDrivenUI

final class DynamicScreenInteractor: DynamicScreenInteracting {
    private let repository: any DynamicScreenRepository
    private let appVersion: String

    init(
        repository: any DynamicScreenRepository = Container.shared.dynamicScreenRepository(),
        appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    ) {
        self.repository = repository
        self.appVersion = appVersion
    }

    func screen(id: String) async throws -> DynamicScreen {
        let payload = try await repository.screen(id: id)
        return try DynamicScreenDecoder.decode(payload.json, appVersion: appVersion)
    }
}
