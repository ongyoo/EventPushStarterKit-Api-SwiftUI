//
//  EventRowView.swift
//  EventPushStarterKit
//
//  Created by kowit on 23/9/2568 BE.
//

import SwiftUI

struct EventRowView: View {
    var events: Event!
    
    var body: some View {
        HStack {
            if let urlString = events.thumbnailUrl,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } placeholder: {
                    Color.gray
                }
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("evnt name: \(events.title)")
                Text("event date: \(events.startDate.relativeDateString())")
            }
            Spacer(minLength: 8)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(
                    color: .brandSecondary.opacity(0.03),
                    radius: 4,
                    x: 0,
                    y: 4
                )
        )
    }
}

#Preview {
    EventRowView()
}
