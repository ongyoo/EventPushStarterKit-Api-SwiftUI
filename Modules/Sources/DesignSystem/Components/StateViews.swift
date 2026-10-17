//
//  StateViews.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import SwiftUI

/// Standard error state with retry.
public struct ErrorStateView: View {
    private let message: String
    private let retry: (() -> Void)?

    /// `ErrorStateView(message: error) { Task { await presenter.load() } }`
    public init(message: String, retry: (() -> Void)? = nil) {
        self.message = message
        self.retry = retry
    }

    public var body: some View {
        ContentUnavailableView {
            Label(DSStrings.errorTitle, systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            if let retry {
                Button(DSStrings.retry, action: retry)
                    .buttonStyle(.borderedProminent)
                    .tint(.brandPrimary)
            }
        }
    }
}

/// Standard empty state.
@MainActor
public struct EmptyStateView: View {
    private let title: String
    private let systemImage: String
    private let message: String?

    /// `EmptyStateView("No events", systemImage: "calendar", message: "Try another day.")`
    public init(_ title: String? = nil, systemImage: String = "tray", message: String? = nil) {
        self.title = title ?? DSStrings.emptyTitle
        self.systemImage = systemImage
        self.message = message
    }

    public var body: some View {
        ContentUnavailableView(title, systemImage: systemImage, description: message.map(Text.init))
    }
}

public extension View {
    /// Shimmering skeleton placeholder. Use on a view filled with sample data:
    ///
    ///     EventRowView(event: .sample).skeleton(isLoading)
    func skeleton(_ isActive: Bool = true) -> some View {
        modifier(SkeletonModifier(isActive: isActive))
    }
}

private struct SkeletonModifier: ViewModifier {
    let isActive: Bool
    @State private var isDimmed = false

    func body(content: Content) -> some View {
        if isActive {
            content
                .redacted(reason: .placeholder)
                .allowsHitTesting(false)
                .opacity(isDimmed ? 0.4 : 1)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isDimmed)
                .onAppear { isDimmed = true }
                .accessibilityLabel(DSStrings.loading)
        } else {
            content
        }
    }
}
