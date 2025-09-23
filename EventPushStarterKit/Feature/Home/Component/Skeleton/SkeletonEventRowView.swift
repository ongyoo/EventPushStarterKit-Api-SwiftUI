//
//  SkeletonEventRowView.swift
//  EventPush
//
//  Created by Nathat Kuanthanom on 9/10/25.
//

import SwiftUI

struct SkeletonEventRowView: View {
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 80)
                .padding(8)
            Spacer()
            VStack(alignment: .leading, spacing: 4){
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 20)
                    .padding(.trailing, 40)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 20)
                    .padding(.trailing, 80)
            }
            .padding(.trailing, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.3))
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
    SkeletonEventRowView()
}
