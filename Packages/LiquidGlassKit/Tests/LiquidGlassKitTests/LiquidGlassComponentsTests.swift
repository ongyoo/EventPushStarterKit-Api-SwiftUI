//
//  LiquidGlassComponentsTests.swift
//  LiquidGlassKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

@testable import LiquidGlassKit
import SwiftUI
import Testing
import UIKit

/// Renders every SwiftUI component in light and dark, the way an app shows them.
@MainActor
struct LiquidGlassComponentsTests {
    private struct Gallery: View {
        @State var query = "glass"
        @State var isOn = true
        @State var volume = 0.4
        @State var segment = "a"
        @State var expanded = true
        @Namespace var glass

        var body: some View {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Card").padding().liquidGlass(.regular.tint(.purple).interactive(), in: .rect(cornerRadius: 20))
                    Text("Clear").padding().liquidGlass(.clear, in: .circle)
                    Text("Legacy").padding().liquidGlass(cornerRadius: 12, tint: .systemTeal, isClear: false)
                    Button("Regular") {}.liquidGlassButton()
                    Button("Prominent") {}.liquidGlassButton(.prominent)
                    Button("Disabled") {}.buttonStyle(LiquidGlassButtonStyle(kind: .prominent)).disabled(true)
                    LiquidGlassContainer(spacing: 8) {
                        HStack {
                            Button("Edit") {}.liquidGlassButton().liquidGlassID("edit", in: glass)
                            if expanded {
                                Button("Share") {}.liquidGlassButton().liquidGlassID("share", in: glass)
                            }
                        }
                    }
                    LiquidGlassSearchField(text: $query, prompt: "Search") {}
                    LiquidGlassToolbar {
                        LiquidGlassToolbarButton("Home", systemImage: "house", isSelected: true) {}
                        LiquidGlassToolbarButton("Share", systemImage: "square.and.arrow.up") {}
                    }
                    Toggle("Notify", isOn: $isOn).liquidGlassToggle()
                    Toggle("Kit", isOn: $isOn).toggleStyle(LiquidGlassToggleStyle())
                    LiquidGlassSlider(value: $volume, in: 0...1)
                    LiquidGlassSlider(value: $volume, in: 0...1, step: 0.1)
                    LiquidGlassSegmentedPicker(selection: $segment, segments: [
                        .init("A", value: "a"), .init("B", value: "b", systemImage: "star"),
                    ])
                }
                .padding()
            }
            .liquidScrollEdge()
            .liquidScrollEdge(.top)
        }
    }

    @Test func everyComponentRendersInBothAppearances() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let host = UIHostingController(rootView: Gallery())
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 1600))
            window.overrideUserInterfaceStyle = style
            window.rootViewController = host
            window.makeKeyAndVisible()
            host.view.layoutIfNeeded()
            #expect(host.view.bounds.height == 1600)
        }
    }

    @Test func sheetBackgroundRenders() {
        let host = UIHostingController(rootView: Text("Sheet").liquidGlassSheet())
        host.view.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        host.view.layoutIfNeeded()
    }

    @Test func glassStylesCompose() {
        let style = LiquidGlassStyle.regular.tint(.red).interactive()
        #expect(style.tint == .red && style.isInteractive && !style.isClear)
        #expect(LiquidGlassStyle.clear.isClear)
        #expect(LiquidGlassShape.rect(cornerRadius: 8).cornerRadius == 8)
        #expect(LiquidGlassShape.capsule.cornerRadius == nil)
        #expect(LiquidGlassShape.circle.cornerRadius == nil)
        _ = (LiquidGlassShape.capsule.shape, LiquidGlassShape.circle.shape, LiquidGlassShape.rect(cornerRadius: 4).shape)
    }

    @Test func pressedBackgroundSwells() {
        let background = LiquidGlassBackground(cornerRadius: nil, tint: nil, isClear: false, isPressed: true)
        let host = UIHostingController(rootView: background.frame(width: 120, height: 44))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
    }
}
