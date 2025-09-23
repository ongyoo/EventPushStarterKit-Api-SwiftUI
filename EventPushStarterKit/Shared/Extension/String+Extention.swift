//
//  String+Extention.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 24/9/2568 BE.
//

import Foundation

extension String {
    func toDateISO8601() -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: self)
    }
}
