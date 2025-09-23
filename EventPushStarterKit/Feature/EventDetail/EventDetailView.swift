//
//  EventDetailView.swift
//  EventPushStarterKit
//
//  Created by Nathat Kuanthanom on 9/17/25.
//

import SwiftUI

struct EventDetailView: View {
    var body: some View {
        ScrollView(.vertical) {
            Image("event-sample1")
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Event Detail View")
                EventMetaDataCard()
                OrganizerRowView()
                About()
                
            }
            .padding(16)
            
        }
        .ignoresSafeArea()
        
    }
}

#Preview {
    EventDetailView()
}
