//
//  ScreenTracking.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import Core
import UIKit

/// Name a screen reports to analytics. Optional: by default the name comes
/// from the type (`EventDetailView` -> `event_detail`).
///
///     final class CheckoutViewController: UIViewController, AnalyticsScreenNaming {
///         let analyticsScreenName = "checkout"
///     }
@MainActor
public protocol AnalyticsScreenNaming {
    var analyticsScreenName: String { get }
}

public extension UIViewController {
    /// What `Navigator` sends as `screen_view` when this screen appears.
    @MainActor
    var resolvedAnalyticsScreenName: String {
        (self as? AnalyticsScreenNaming)?.analyticsScreenName ?? ScreenName.from(typeName: String(describing: type(of: self)))
    }
}

/// Turns type names into snake_case screen names.
public enum ScreenName {
    /// `"EventDetailView"` -> `"event_detail"`, `"NotificationViewController"` -> `"notification"`,
    /// `"ModifiedContent<HomeView, _>"` -> `"modified_content"` (name such screens explicitly).
    public static func from(typeName: String) -> String {
        var name = String(typeName.prefix { $0 != "<" && $0 != "(" })
        for suffix in ["ViewController", "Controller", "View", "Screen"] where name.hasSuffix(suffix) && name.count > suffix.count {
            name.removeLast(suffix.count)
            break
        }
        // Acronyms stay together: "URLSettings" -> "url_settings".
        let characters = Array(name)
        var result = ""
        for (index, character) in characters.enumerated() {
            if character.isUppercase, index > 0 {
                let previous = characters[index - 1]
                let nextIsLower = index + 1 < characters.count && characters[index + 1].isLowercase
                if previous.isLowercase || previous.isNumber || (previous.isUppercase && nextIsLower) {
                    result.append("_")
                }
            }
            result.append(contentsOf: character.lowercased())
        }
        return result.isEmpty ? "screen" : result
    }
}
