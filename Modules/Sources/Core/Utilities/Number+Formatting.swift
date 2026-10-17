//
//  Number+Formatting.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation

public extension Double {
    /// "฿1,200.00" using the given ISO currency code.
    func currencyText(code: String = "THB") -> String {
        formatted(.currency(code: code).locale(AppLocale.current))
    }

    /// "9.7K"
    var compactText: String {
        formatted(.number.notation(.compactName).locale(AppLocale.current))
    }
}

public extension Int {
    /// "9.7K"
    var compactText: String {
        formatted(.number.notation(.compactName).locale(AppLocale.current))
    }
}
