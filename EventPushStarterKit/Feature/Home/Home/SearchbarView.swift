//
//  SearchbarView.swift
//  EventPushStarterKit
//
//  Created by kowit on 22/9/2568 BE.
//


import SwiftUI

struct SearchbarView: View {
    var body: some View {
        NavigationLink {
            
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                Text("Search")
                Spacer()
                
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12)
                .stroke(Color.divider)
            )
            
        }
        .buttonStyle(.plain)
        .padding(16)
        
    }
}
