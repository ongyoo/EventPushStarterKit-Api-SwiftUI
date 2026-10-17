//
//  AnimationGallery.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import SwiftUI

/// Live catalog of every animation helper. Open it in a preview, or in a
/// Debug build with the deep link `<scheme>://debug/animations`.
public struct AnimationGallery: View {
    @State private var replayID = 0
    @State private var shakeCount = 0
    @State private var likes = 0
    @State private var price: Double = 1_200
    @State private var showBanner = false

    /// `NavigationStack { AnimationGallery() }`
    public init() {}

    public var body: some View {
        List {
            Section("Appear (tap Replay)") {
                ForEach(AppearStyle.allCases, id: \.self) { style in
                    sample(style.name)
                        .appearAnimation(style)
                        .id("\(style.name)-\(replayID)")
                }
                Button("Replay") { replayID += 1 }
            }

            Section("Staggered list") {
                ForEach(0..<4, id: \.self) { index in
                    sample("Item \(index + 1)")
                        .staggeredAppear(index: index)
                        .id("stagger-\(index)-\(replayID)")
                }
            }

            Section("Effects") {
                sample("Shake (tap)")
                    .shake(trigger: shakeCount)
                    .onTapGesture { shakeCount += 1 }
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.pink)
                        .pop(trigger: likes)
                    Text("Pop: \(likes) likes (tap)")
                }
                .onTapGesture { likes += 1 }
                sample("Pulse").pulse()
                sample("Floating").floating()
                sample("Shimmer").shimmer()
                Button("Pressable button style") {}
                    .buttonStyle(.pressable)
            }

            Section("Numbers & transitions") {
                AnimatedNumberText(value: price, format: .currency(code: "THB"))
                    .font(.dsTitle)
                Button("Change price") { price = Double(Int.random(in: 100...9_999)) }
                Button(showBanner ? "Hide banner" : "Show banner") {
                    withAnimation(.dsSpring) { showBanner.toggle() }
                }
                if showBanner {
                    sample("Slide-down banner").transition(.dsSlideDown)
                }
            }
        }
        .navigationTitle("Animations")
    }

    private func sample(_ title: String) -> some View {
        Text(title)
            .font(.dsCallout)
            .foregroundStyle(.white)
            .padding(.horizontal, .m)
            .padding(.vertical, .xs)
            .background(Capsule().fill(LinearGradient.brand))
    }
}

#Preview {
    NavigationStack { AnimationGallery() }
}
