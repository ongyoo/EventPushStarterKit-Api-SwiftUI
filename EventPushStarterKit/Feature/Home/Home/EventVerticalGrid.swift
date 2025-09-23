//
//  EventVerticalGrid.swift
//  EventPushStarterKit
//
//  Created by kowit on 23/9/2568 BE.
//


import SwiftUI

let columns = [
        GridItem(.flexible())
    ]

struct EventVerticalGrid: View {
    var events: [Event] = []
    private let columns = [GridItem(.flexible())]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(events) { event in
                NavigationLink(destination: EventDetailView()) {
                    EventRowView(events: event)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
    }
}
