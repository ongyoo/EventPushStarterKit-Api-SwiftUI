//
//  Double+Extension.swift
//  EventPush
//
//  Created by Nathat Kuanthanom on 9/4/25.
//

import Foundation

extension Double {
    func formatedCurrency() -> String {
        return String(format: "%.2f", self)
    }
    
    func formattedNoDigit() -> String {
        return String(format: "%.0f", self)
    }
}
