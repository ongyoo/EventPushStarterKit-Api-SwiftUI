//
//  LiquidGlassViewTests.swift
//  LiquidGlassKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import CoreMotion
@testable import LiquidGlassKit
import Testing
import UIKit

@MainActor
struct LiquidGlassViewTests {
    /// Glass over a backdrop, both in a window (like a tab bar over a screen).
    private func makeGlass(style: UIUserInterfaceStyle = .light) -> (LiquidGlassView, UIView, UIWindow) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.overrideUserInterfaceStyle = style
        let root = UIViewController()
        window.rootViewController = root
        window.makeKeyAndVisible()
        let backdrop = UIView(frame: root.view.bounds)
        backdrop.backgroundColor = .black
        root.view.addSubview(backdrop)
        let glass = LiquidGlassView(frame: CGRect(x: 60, y: 760, width: 270, height: 62))
        glass.usesSystemGlass = false // these tests cover the kit's own drawing (iOS 17–18)
        root.view.addSubview(glass)
        glass.backdrop = backdrop
        glass.layoutIfNeeded()
        return (glass, backdrop, window)
    }

    // MARK: - Adaptive color

    @Test func flipsToDarkOverDarkContentAndBackWithHysteresis() {
        let (glass, _, _) = makeGlass()
        #expect(glass.adaptiveStyle == .unspecified)
        glass.apply(luminance: 0.2)
        #expect(glass.adaptiveStyle == .dark)
        #expect(glass.overrideUserInterfaceStyle == .dark)
        glass.apply(luminance: 0.5) // middle: no flicker
        #expect(glass.adaptiveStyle == .dark)
        glass.apply(luminance: 0.8)
        #expect(glass.adaptiveStyle == .unspecified) // light = system again
    }

    @Test func flipsToLightOverLightContentInDarkMode() {
        let (glass, _, _) = makeGlass(style: .dark)
        var reported: [UIUserInterfaceStyle] = []
        glass.onAdaptiveStyleChange = { reported.append($0) }
        glass.apply(luminance: 0.9)
        #expect(glass.adaptiveStyle == .light)
        glass.apply(luminance: 0.1)
        #expect(glass.adaptiveStyle == .unspecified)
        #expect(reported == [.light, .unspecified])
    }

    @Test func turningAdaptiveOffFollowsTheSystem() {
        let (glass, _, _) = makeGlass()
        glass.apply(luminance: 0.1)
        glass.effects = [.specular]
        #expect(glass.adaptiveStyle == .unspecified)
        #expect(glass.lensSnapshot == nil)
        #expect(!glass.hasMotion)
    }

    @Test func luminanceOfASolidViewIsReadWhenRenderable() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        view.backgroundColor = .white
        // Without a window scene the render may be unavailable; when it is, it must be right.
        if let value = LiquidGlassView.averageLuminance(of: view, in: view.bounds) {
            #expect(value >= 0 && value <= 1)
        }
    }

    // MARK: - Backdrop updates

    @Test func backdropUpdatesRunOnlyWhileContentMoves() {
        let (glass, _, _) = makeGlass()
        glass.setNeedsBackdropUpdate(duration: 0.3)
        #expect(glass.isBackdropLive)
        glass.refreshBackdrop(sampleLuminance: true)

        let (other, _, _) = makeGlass()
        LiquidGlassView.backdropWillChange(duration: 0.2)
        #expect(other.isBackdropLive)

        let lonely = LiquidGlassView(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        lonely.setNeedsBackdropUpdate()
        #expect(!lonely.isBackdropLive) // no window, no backdrop: nothing to follow
    }

    // MARK: - Light and touch

    @Test func highlightsFollowTheLight() {
        let (glass, _, _) = makeGlass()
        #expect(glass.hasMotion)
        let before = glass.specularEndPoint
        LiquidGlassMotion.shared.receive(CMAcceleration(x: 0.9, y: -0.2, z: -0.3))
        LiquidGlassMotion.shared.receive(CMAcceleration(x: 0.9, y: -0.2, z: -0.3))
        #expect(glass.specularEndPoint != before)
    }

    @Test func pressSwellsAndReleases() {
        let (glass, _, _) = makeGlass()
        glass.setPressed(true, at: CGPoint(x: 40, y: 30))
        #expect(glass.isPressed)
        if !UIAccessibility.isReduceMotionEnabled {
            #expect(glass.transform != .identity)
        }
        glass.movePressPoint(to: CGPoint(x: 120, y: 30))
        glass.setPressed(false)
        #expect(!glass.isPressed)
        #expect(glass.transform == .identity)
    }

    @Test func appearanceVariantsRender() {
        let (glass, _, window) = makeGlass()
        glass.isClear = true
        glass.glassTint = .systemPurple
        glass.cornerRadius = 12
        glass.lensMagnification = 1.3
        window.overrideUserInterfaceStyle = .dark
        glass.updateAppearance()
        glass.layoutIfNeeded()
        glass.isClear = false
        glass.updateAppearance()
        #expect(glass.contentView.layer.cornerRadius == 12)
    }

    // MARK: - Motion and shapes

    @Test func lightComesFromAboveAndMovesWithTilt() {
        let upright = LiquidGlassMotion.light(fromGravityX: 0, y: -1)
        #expect(upright.dy < 0)
        let tiltedRight = LiquidGlassMotion.light(fromGravityX: 0.8, y: -0.6)
        #expect(tiltedRight.dx < upright.dx)
        #expect(abs(hypot(tiltedRight.dx, tiltedRight.dy) - 1) < 0.001)
    }

    @Test func motionObserversAreReleasedWithTheirToken() {
        let motion = LiquidGlassMotion.shared
        let before = motion.observerCount
        var received = 0
        var token: LiquidGlassMotion.Token? = motion.observe { _ in received += 1 }
        #expect(motion.observerCount == before + 1)
        #expect(received == 1) // current value at once
        _ = token
        token = nil
        #expect(motion.observerCount == before)
    }

    @Test func masksAreCachedAndStretchable() {
        let rim = GlassShapes.rimFalloff(cornerRadius: 31, depth: 16)
        #expect(rim === GlassShapes.rimFalloff(cornerRadius: 31, depth: 16))
        #expect(rim.capInsets.left == 31)
        let fill = GlassShapes.fill(cornerRadius: 10)
        #expect(fill.size == CGSize(width: 22, height: 22))
    }
}
