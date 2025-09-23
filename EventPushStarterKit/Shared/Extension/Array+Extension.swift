//
//  Array+Extension.swift
//  EventPush
//
//  Created by Nathat Kuanthanom on 9/4/25.
//

import Foundation

extension Array {
    func limit(_ limit: Int) -> [Element] {
        guard count > limit else {
            return self
        }
        return Array(self[0..<limit])
    }
}
