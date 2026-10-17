//
//  LocalizationTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import Domain
@testable import Features
import Foundation
import Testing
import UIKit

/// Every key must exist in every language (catches missing translations in CI).
@MainActor
struct LocalizationTests {
    private func keys() throws -> [String] {
        let url = try #require(Bundle.module.url(forResource: "en", withExtension: "lproj"))
        let strings = try #require(NSDictionary(contentsOf: url.appendingPathComponent("Localizable.strings")) as? [String: Any])
        let plurals = (NSDictionary(contentsOf: url.appendingPathComponent("Localizable.stringsdict")) as? [String: Any]) ?? [:]
        return Array(strings.keys) + Array(plurals.keys)
    }

    @Test(arguments: ["en", "th"])
    func everyKeyIsTranslated(language: String) throws {
        let manager = LocalizationManager(supportedCodes: [language], defaults: UserDefaults(suiteName: "l10n.\(language)") ?? .standard, systemLanguages: [language])
        let all = try keys()
        #expect(all.count > 50)
        for key in all {
            #expect(manager.localized(key, bundle: .module) != key, "\(key) missing in \(language)")
        }
    }

    @Test func typedAccessorsAndPlurals() {
        LocalizationManager.shared.select(.language("en"))
        #expect(L10n.Event.eventsCount(1) == "1 event")
        #expect(L10n.Event.eventsCount(3) == "3 events")
        #expect(L10n.category(.music) == "Music")
        #expect(L10n.permission(.camera) == "Camera")
        for status in [PermissionStatus.notDetermined, .authorized, .limited, .provisional, .denied, .restricted, .unavailable("x")] {
            #expect(!L10n.permissionStatus(status).isEmpty)
        }
        #expect(![L10n.Tab.home, L10n.Tab.inbox, L10n.Tab.settings, L10n.Inbox.empty, L10n.Inbox.title,
                  L10n.Events.filter, L10n.Events.allTitle, L10n.Events.emptyMessage, L10n.Home.title,
                  L10n.Home.clearSearch, L10n.Home.notifications, L10n.Event.free, L10n.Event.about].contains(""))

        let thai = LocalizationManager(supportedCodes: ["en", "th"], defaults: UserDefaults(suiteName: "l10n.thai") ?? .standard, systemLanguages: ["th"])
        #expect(thai.localized("home.popular", bundle: .module) == "ยอดนิยม")
        LocalizationManager.shared.select(.system)
    }
}

@MainActor
struct FlipAnimatorTests {
    @Test func flipRunsBothDirections() {
        for presenting in [true, false] {
            let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
            let context = SimpleTransitionContext(container: container)
            let animator = FlipAnimator(isPresenting: presenting, duration: 0)
            #expect(animator.transitionDuration(using: nil) == 0)
            animator.animateTransition(using: context)
            #expect(container.subviews.contains(context.to.view))
        }
        #expect(HeroID.event("7") == "event.7")
    }
}

/// Minimal context to run animators synchronously in tests.
final class SimpleTransitionContext: NSObject, UIViewControllerContextTransitioning {
    let containerView: UIView
    let from = UIViewController()
    let to = UIViewController()
    private(set) var completed: Bool?

    init(container: UIView) {
        self.containerView = container
        super.init()
        container.addSubview(from.view)
    }

    var isAnimated: Bool { false }
    var isInteractive: Bool { false }
    var transitionWasCancelled: Bool { false }
    var presentationStyle: UIModalPresentationStyle { .fullScreen }
    var targetTransform: CGAffineTransform { .identity }
    func updateInteractiveTransition(_ percentComplete: CGFloat) {}
    func finishInteractiveTransition() {}
    func cancelInteractiveTransition() {}
    func pauseInteractiveTransition() {}
    func completeTransition(_ didComplete: Bool) { completed = didComplete }
    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? { key == .from ? from : to }
    func view(forKey key: UITransitionContextViewKey) -> UIView? { key == .from ? from.view : to.view }
    func initialFrame(for vc: UIViewController) -> CGRect { containerView.bounds }
    func finalFrame(for vc: UIViewController) -> CGRect { containerView.bounds }
}
