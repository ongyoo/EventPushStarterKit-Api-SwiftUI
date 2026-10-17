//
//  CategoryBarView.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import DesignSystem
import Domain
import SwiftUI

struct CategoryBarView: View {
    let categories: [EventCategory]
    let selected: EventCategory
    let onSelect: (EventCategory) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Space.xs.rawValue) {
                ForEach(categories, id: \.self) { category in
                    CategoryChipView(category: category, isSelected: category == selected) {
                        onSelect(category)
                    }
                }
            }
            .pageMargin()
        }
    }
}

struct CategoryChipView: View {
    let category: EventCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(L10n.category(category), systemImage: category.iconName)
                .font(.dsCallout)
                .foregroundStyle(isSelected ? Color.white : .textPrimary)
                .padding(.horizontal, .m)
                .padding(.vertical, .xs)
                .frame(minHeight: DS.Size.minTapTarget)
                .background {
                    Capsule().fill(isSelected ? AnyShapeStyle(LinearGradient.brand) : AnyShapeStyle(Color.backgroundPrimary))
                }
                .overlay { Capsule().strokeBorder(isSelected ? Color.clear : .border) }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
