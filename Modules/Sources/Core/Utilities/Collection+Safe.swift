//
//  Collection+Safe.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation

public extension Collection {
    /// `array[safe: 10]` returns nil instead of crashing.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

public extension Array {
    /// First `count` elements (or all, if fewer).
    func limited(to count: Int) -> [Element] {
        Array(prefix(count))
    }
}
