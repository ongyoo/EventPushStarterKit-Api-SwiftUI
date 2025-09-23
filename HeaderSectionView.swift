//
//  HeaderSectionView.swift
//  EventPushStarterKit
//
//  Created by kowit on 22/9/2568 BE.
//


import SwiftUI

struct HeaderSectionView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Current Location")
                Text("Bangkok")
            }
            Spacer()
            
            NavigationLink {
                EventDetailView()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 52, height: 52)
                    Image(systemName: "bell.fill")
                }
            }
            .buttonStyle(.plain)
        }
        .padding(16)
    }
}

