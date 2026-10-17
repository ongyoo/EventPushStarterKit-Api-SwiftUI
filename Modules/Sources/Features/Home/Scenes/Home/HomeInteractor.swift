//
//  HomeInteractor.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Domain
import Foundation

final class HomeInteractor: HomeInteracting {
    private let highlights: GetEventHighlightsUseCase

    init(repository: any EventRepository = Container.shared.eventRepository()) {
        highlights = GetEventHighlightsUseCase(repository: repository)
    }

    func loadContent() async throws -> HomeContent {
        let result = try await highlights()
        return HomeContent(featured: result.featured, upcoming: result.upcoming)
    }
}
