//
//  HomeContentLoadingSkeleton.swift
//  EventPush
//
//  Created by Nathat Kuanthanom on 9/10/25.
//

import SwiftUI

struct HomeContentLoadingSkeleton: View {
    var body: some View {
        Group {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<2) { _ in
                        SkeletonImageCardView()
                    }
                }
                .horizontalContentPadding()
            }
            
            VStack(spacing: 12) {
                ForEach(0..<3) { _ in
                    SkeletonEventRowView()
                }
            }
            .padding(.bottom, 32)
            .horizontalContentPadding()
        }
        .padding(.top, 12)
    }
}

#Preview {
    HomeContentLoadingSkeleton()
}
