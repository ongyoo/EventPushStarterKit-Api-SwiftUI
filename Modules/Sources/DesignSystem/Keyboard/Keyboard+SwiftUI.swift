//
//  Keyboard+SwiftUI.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import SwiftUI

public extension View {
    /// Return key moves to the next field; the last one shows "Done" and hides the keyboard.
    ///
    ///     enum Field { case name, email, password }
    ///     @FocusState private var focus: Field?
    ///
    ///     TextField("Name", text: $name).focused($focus, equals: .name).focusNext($focus, to: .email)
    ///     TextField("Email", text: $email).focused($focus, equals: .email).focusNext($focus, to: .password)
    ///     SecureField("Password", text: $password).focused($focus, equals: .password).focusNext($focus, to: nil)
    func focusNext<Field: Hashable>(_ focus: FocusState<Field?>.Binding, to next: Field?) -> some View {
        submitLabel(next == nil ? .done : .next)
            .onSubmit { focus.wrappedValue = next }
    }

    /// Adds a "Done" button above the keyboard (number pads have no return key).
    ///
    ///     TextField("Amount", text: $amount).keyboardType(.decimalPad).keyboardDoneButton()
    func keyboardDoneButton(_ title: String = "Done") -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(title) { Keyboard.dismiss() }
                    .fontWeight(.semibold)
            }
        }
    }

    /// Tapping the empty background of this view hides the keyboard
    /// (already app-wide through `Keyboard.enableTapToDismiss`; use this in
    /// previews or views shown outside the app window).
    func dismissKeyboardOnTap() -> some View {
        background {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { Keyboard.dismiss() }
        }
    }

    /// Bottom padding equal to the keyboard height, animated with it. For views
    /// that ignore the keyboard safe area (e.g. inside `.ignoresSafeArea()`).
    func keyboardPadding(extra: CGFloat = 0) -> some View {
        modifier(KeyboardPaddingModifier(extra: extra))
    }
}

private struct KeyboardPaddingModifier: ViewModifier {
    let extra: CGFloat
    private let keyboard = KeyboardObserver.shared

    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboard.isVisible ? keyboard.height + extra : 0)
            .animation(.easeOut(duration: keyboard.animationDuration), value: keyboard.height)
    }
}
