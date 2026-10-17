//
//  DS.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import SwiftUI

/// Design tokens. Never hard-code spacing, radius or colors in features:
///
///     .padding(.m)            // 16pt
///     .cornerRadius(.l)       // 16pt
///     .foregroundStyle(.brandPrimary)
public enum DS {
    /// Spacing scale: `.padding(.m)`.
    public enum Space: CGFloat, CaseIterable, Sendable {
        case xxs = 4
        case xs = 8
        case s = 12
        case m = 16
        case l = 20
        case xl = 24
        case xxl = 32
        case xxxl = 48
    }

    /// Corner radius scale: `.cornerRadius(.l)`.
    public enum Radius: CGFloat, Sendable {
        case s = 8
        case m = 12
        case l = 16
        case xl = 24
        case pill = 999
    }

    /// Fixed sizes.
    public enum Size {
        /// Minimum tap target (Apple HIG).
        public static let minTapTarget: CGFloat = 44
        /// Max width for readable text / forms on iPad and landscape.
        public static let readableWidth: CGFloat = 680
    }
}
