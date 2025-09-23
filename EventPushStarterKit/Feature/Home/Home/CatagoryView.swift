//
//  CatagoryView.swift
//  EventPushStarterKit
//
//  Created by kowit on 22/9/2568 BE.
//

import SwiftUI

struct CatagoryView: View {
    var body: some View {
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(0..<10) { _ in
                    CataggoryMenuView()
                }
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 0)
    }
}

#Preview {
    CatagoryView()
}
