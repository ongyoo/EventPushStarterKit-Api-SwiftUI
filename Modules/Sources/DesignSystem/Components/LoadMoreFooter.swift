//
//  LoadMoreFooter.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Core
import SwiftUI

/// Bottom of a paginated list: spinner while loading more, retry on error,
/// nothing otherwise.
///
///     LoadMoreFooter(phase: paginator.phase) { Task { await paginator.loadNextPage() } }
public struct LoadMoreFooter: View {
    private let isLoading: Bool
    private let errorMessage: String?
    private let retry: () -> Void

    public init(isLoading: Bool, errorMessage: String?, retry: @escaping () -> Void) {
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.retry = retry
    }

    public init<Item>(phase: Paginator<Item>.Phase, retry: @escaping () -> Void) {
        switch phase {
        case .loadingMore: self.init(isLoading: true, errorMessage: nil, retry: retry)
        case let .failedToLoadMore(message): self.init(isLoading: false, errorMessage: message, retry: retry)
        default: self.init(isLoading: false, errorMessage: nil, retry: retry)
        }
    }

    public var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .accessibilityLabel(DSStrings.loading)
            } else if let errorMessage {
                VStack(spacing: DS.Space.xs.rawValue) {
                    Text(errorMessage)
                        .font(.dsCaption)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                    Button(DSStrings.retry, action: retry)
                        .buttonStyle(.bordered)
                        .tint(.brandPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: isLoading || errorMessage != nil ? 56 : 0)
        .padding(.vertical, .s)
    }
}
