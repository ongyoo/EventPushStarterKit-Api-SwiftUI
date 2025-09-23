//
//  EventHorizontalGrid.swift
//  EventPushStarterKit
//
//  Created by kowit on 23/9/2568 BE.
//


import SwiftUI

let rows = [
    GridItem(.fixed(184))
]

struct EventHorizontalGrid: View {
    var events: [Event] = []
    private let rows = [GridItem(.fixed(184))]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: rows, spacing: 16) {
                ForEach(events) { event in
                    NavigationLink {
                        EventDetailView()
                    } label: {
                        ImageCardView(thumbnailUrl: event.thumbnailUrl,
                                      startDate: event.startDate)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
