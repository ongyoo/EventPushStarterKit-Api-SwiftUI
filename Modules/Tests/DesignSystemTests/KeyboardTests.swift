//
//  KeyboardTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
@testable import DesignSystem
import SwiftUI
import Testing
import UIKit

@MainActor
struct KeyboardTests {
    @Test func observerTracksHeightFromNotifications() {
        let center = NotificationCenter()
        let observer = KeyboardObserver(center: center)
        var heights: [CGFloat] = []
        observer.onChange = { heights.append($0) }

        let screen = UIScreen.main
        let frame = CGRect(x: 0, y: screen.bounds.height - 300, width: screen.bounds.width, height: 300)
        center.post(name: UIResponder.keyboardWillChangeFrameNotification, object: screen, userInfo: [
            UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: frame),
            UIResponder.keyboardAnimationDurationUserInfoKey: 0.3,
        ])
        #expect(observer.height == 300 && observer.isVisible && observer.animationDuration == 0.3)

        center.post(name: UIResponder.keyboardWillHideNotification, object: screen, userInfo: [:])
        #expect(observer.height == 0 && !observer.isVisible)
        #expect(heights == [300, 0])
    }

    @Test func tapToDismissIgnoresTextInputsAndInstallsOnce() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let before = window.gestureRecognizers?.count ?? 0
        Keyboard.enableTapToDismiss(in: window)
        Keyboard.enableTapToDismiss(in: window)
        #expect((window.gestureRecognizers?.count ?? 0) == before + 1, "Installed once")

        let field = UITextField()
        let label = UILabel()
        field.addSubview(label)
        #expect(TapToDismiss.isTextInput(field))
        #expect(TapToDismiss.isTextInput(label), "Inside a text field")
        #expect(!TapToDismiss.isTextInput(UIButton()))
        #expect(!TapToDismiss.isTextInput(nil))

        let handler = TapToDismiss(window: window)
        handler.handleTap()
        #expect(handler.gestureRecognizer(UITapGestureRecognizer(), shouldRecognizeSimultaneouslyWith: UITapGestureRecognizer()))
        Keyboard.dismiss()   // safe outside an app
    }

    @Test func textFieldChainMovesToNextAndFinishes() {
        let fields = [UITextField(), UITextField(), UITextField()]
        var done = 0
        let chain = TextFieldChain(fields) { done += 1 }
        #expect(fields.map(\.returnKeyType) == [.next, .next, .done])
        chain.didReturn(from: 0)
        chain.didReturn(from: 2)
        #expect(done == 1)
    }

    @Test func scrollViewInsetFollowsKeyboard() {
        let observer = KeyboardObserver(center: NotificationCenter())
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let field = UITextField(frame: CGRect(x: 0, y: 700, width: 300, height: 40))
        scrollView.addSubview(field)
        scrollView.adjustsForKeyboard(observer: observer)
        scrollView.adjustsForKeyboard(observer: observer)   // once only

        observer.update(KeyboardInfo(visibleHeight: 320, duration: 0, isHiding: false))
        #expect(scrollView.contentInset.bottom == 320)
        observer.update(KeyboardInfo(visibleHeight: 0, duration: 0, isHiding: true))
        #expect(scrollView.contentInset.bottom == 0)
        #expect(scrollView.firstResponderDescendant == nil)
    }

    @Test func pinAboveKeyboardAddsConstraints() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let bar = UIView()
        container.pinAboveKeyboard(bar, spacing: 8)
        #expect(bar.superview === container)
        #expect(!bar.translatesAutoresizingMaskIntoConstraints)
    }

    @Test func swiftUIModifiersRender() {
        enum Field { case a, b }
        struct Form: View {
            @FocusState var focus: Field?
            var body: some View {
                VStack {
                    TextField("A", text: .constant("")).focused($focus, equals: .a).focusNext($focus, to: .b)
                    TextField("B", text: .constant("")).focused($focus, equals: .b).focusNext($focus, to: nil)
                }
                .keyboardDoneButton()
                .dismissKeyboardOnTap()
                .keyboardPadding(extra: 8)
            }
        }
        let host = UIHostingController(rootView: Form())
        host.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        host.view.layoutIfNeeded()
        #expect(host.view != nil)
        _ = LoadMoreFooter(phase: Paginator<Int2>.Phase.loadingMore) {}
        _ = LoadMoreFooter(phase: Paginator<Int2>.Phase.failedToLoadMore("x")) {}
        _ = LoadMoreFooter(phase: Paginator<Int2>.Phase.loaded) {}
    }
}

private struct Int2: Identifiable, Sendable { let id: Int }
