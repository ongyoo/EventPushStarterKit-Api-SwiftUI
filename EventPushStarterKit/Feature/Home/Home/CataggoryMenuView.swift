//
//  CataggoryMenuView.swift
//  EventPushStarterKit
//
//  Created by kowit on 22/9/2568 BE.
//

import SwiftUI

struct CataggoryMenuView: View {
    var body: some View {
        
        HStack {
            Image(systemName: "chart.bar.fill")
            Text("All")
        }
        .foregroundStyle(.white)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 360)
                .stroke(Color.border)
        )
        .background(
            RoundedRectangle(cornerRadius: 360)
                .fill(
                    AnyShapeStyle(LinearGradient(
                        colors: Color.gradientPurple,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                )
        )
        
    }
}
