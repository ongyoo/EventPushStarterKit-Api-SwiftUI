//
//  LiquidGlass.swift
//  LiquidGlassKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Foundation

/// Facts about the system design, shared by the kit's `.belowIOS26(...)` options.
public enum LiquidGlass {
    /// `true` on iOS 26+, where UIKit already draws Liquid Glass, unless the
    /// app opts out (`UIDesignRequiresCompatibility = YES` keeps the iOS 18 look).
    public static var isSystemDesign: Bool {
        guard #available(iOS 26, *) else { return false }
        return Bundle.main.object(forInfoDictionaryKey: "UIDesignRequiresCompatibility") as? Bool != true
    }
}
