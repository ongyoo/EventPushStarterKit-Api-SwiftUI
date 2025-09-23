//
//  SkeletonNotificationRowView.swift
//  EventPush
//
//  Created by Nathat Kuanthanom on 9/11/25.
//

import SwiftUI

struct SkeletonNotificationRowView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 16)
                    .padding(.trailing, 60)
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                
                    .frame(height: 14)
                    .padding(.trailing, 40)
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 12)
            }
            
            Spacer()
        }
    }
}

#Preview {
    SkeletonNotificationRowView()
}
