//
//  HomeView.swift
//  EventPushStarterKit
//
//  Created by Nathat Kuanthanom on 9/16/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 16) {
                HeaderSectionView()
                SearchbarView()
                CatagoryView()
                ListSectionHeader()
                EventHorizontalGrid(events: viewModel.events)
                ListSectionHeader()
                EventVerticalGrid(events: viewModel.events)
            }
        }
        .onAppear {
            Task {
                await viewModel.loadEvents()
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
