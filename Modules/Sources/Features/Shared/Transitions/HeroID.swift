//
//  HeroID.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

import Foundation

/// Ids shared by `.transitionSource(id:)` (the view) and `.expand(sourceID:)`
/// (the navigation), so both sides always agree.
public enum HeroID {
    public static func event(_ id: String) -> String { "event.\(id)" }
}
