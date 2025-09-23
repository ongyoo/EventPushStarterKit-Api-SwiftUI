//
//  ImageCardView.swift
//  EventPushStarterKit
//
//  Created by kowit on 23/9/2568 BE.
//

import SwiftUI

struct ImageCardView: View {
    var thumbnailUrl: String?
    var startDate: Date?
    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack {
                if let urlString = thumbnailUrl,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 267, height: 184)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } placeholder: {
                        Color.gray
                    }
                    .scaledToFill()
                    .frame(width: 267, height: 184)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                
                VStack {
                    Text(startDate?.formattedMonth() ?? "")
                        .font(.system(size: 10, weight: .regular))
                    Text(startDate?.formattedDay() ?? "")
                        .font(.system(size: 14, weight: .regular))
                    
                }
                .padding(4)
            }
            .padding([.top, .leading], 8)
        }
    }
}

#Preview {
    ImageCardView()
}
