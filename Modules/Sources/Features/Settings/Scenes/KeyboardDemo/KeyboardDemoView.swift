//
//  KeyboardDemoView.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import DesignSystem
import SwiftUI

/// Every keyboard helper on one screen (Settings → Developer → Keyboard).
struct KeyboardDemoView: View {
    enum Field: Hashable { case name, email, password, amount, note }

    @FocusState private var focus: Field?
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var amount = ""
    @State private var note = ""
    private let keyboard = KeyboardObserver.shared

    var body: some View {
        Form {
            Section {
                TextField(L10n.tr("keyboard.name"), text: $name)
                    .textContentType(.name)
                    .focused($focus, equals: .name)
                    .focusNext($focus, to: .email)
                TextField(L10n.tr("keyboard.email"), text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focus, equals: .email)
                    .focusNext($focus, to: .password)
                SecureField(L10n.tr("keyboard.password"), text: $password)
                    .textContentType(.password)
                    .focused($focus, equals: .password)
                    .focusNext($focus, to: .amount)
                TextField(L10n.tr("keyboard.amount"), text: $amount)
                    .keyboardType(.decimalPad)          // no return key: the toolbar Done button helps
                    .focused($focus, equals: .amount)
                TextField(L10n.tr("keyboard.note"), text: $note, axis: .vertical)
                    .lineLimit(3...6)
                    .focused($focus, equals: .note)
            } footer: {
                Text(L10n.tr("keyboard.footer"))
            }

            Section {
                Text(L10n.tr("keyboard.height", Int(keyboard.height)))
                    .monospacedDigit()
                    .foregroundStyle(keyboard.isVisible ? Color.brandPrimary : .textSecondary)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneButton(L10n.tr("keyboard.done"))
        .onAppear { focus = .name }
    }
}

#Preview {
    NavigationStack { KeyboardDemoView() }
}
