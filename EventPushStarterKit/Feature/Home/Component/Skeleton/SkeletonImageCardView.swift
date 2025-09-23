//
//  SkeletonImageCardView.swift
//  EventPush
//
//  Created by Nathat Kuanthanom on 9/10/25.
//

import SwiftUI

struct SkeletonImageCardView: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 267, height: 184)
            
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .padding([.top, .leading], 8)
        }
    }
}

#Preview {
    SkeletonImageCardView()
}
