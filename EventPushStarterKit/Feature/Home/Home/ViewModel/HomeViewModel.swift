//
//  HomeViewModel.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 23/9/2568 BE.
//
import Foundation


@MainActor
final class HomeViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    private let service: EventServiceProtocol
    
    init(service: EventServiceProtocol = EventService()) {
        self.service = service
    }
    
    func loadEvents() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetchedEvents = try await service.fetchEvents()
            self.events = fetchedEvents
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
