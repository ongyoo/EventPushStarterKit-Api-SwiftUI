//
//  EventMetaDataCard.swift
//  EventPushStarterKit
//
//  Created by kowit on 22/9/2568 BE.
//

import SwiftUI

struct EventMetaDataCard: View {
    
    
    var body: some View {
        HStack(spacing: 0) {
            EventMetaDataItemView(imageName: "dollarsign.circle.fill",
                                  title: "Location",
                                  suntitle: "Bangkok")
            Divider()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            EventMetaDataItemView(imageName: "dollarsign.circle.fill",
                                  title: "Location",
                                  suntitle: "Bangkok")
            Divider()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            EventMetaDataItemView(imageName: "dollarsign.circle.fill",
                                  title: "Location",
                                  suntitle: "Bangkok")
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16).fill(.white)
        )
        .shadow(
            color: Color(hex: "#B15CDE1A"),
            radius: 32,
            x: 0,
            y: 8
        )

    }
    
}

#Preview {
    EventMetaDataCard()
}
