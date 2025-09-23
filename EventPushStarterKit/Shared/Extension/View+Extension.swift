//
//  View+Extension.swift
//  EventPush
//
//  Created by Nathat Kuanthanom on 9/10/25.
//

import SwiftUI

extension View {
    func padding(_ dsSpace: DS.Space) -> some View {
        padding(dsSpace.rawValue)
    }
    
    func padding(_ edges: Edge.Set, _ dsSpace: DS.Space) -> some View {
        padding(edges, dsSpace.rawValue)
    }
    
    func cornerRadius(_ dsRadius: DS.Radius) -> some View {
        cornerRadius(dsRadius.rawValue)
    }
    
    func contentPadding() -> some View {
        self.padding(.horizontal, 16)
    }
    
    func horizontalContentPadding() -> some View {
        self.padding(.horizontal, 16)
    }
    
    func verticalSectionPadding() -> some View {
        self.padding(.vertical, 12)
    }
    
    func sectionLinkStyle() -> some View {
        self.font(.system(size: 14, weight: .regular))
            .foregroundStyle(Color.brandPrimary)
    }
}
