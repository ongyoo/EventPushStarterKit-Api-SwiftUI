//
//  EventCategory.swift
//  EventPush
//
//  Created by Nathat Kuanthanom on 9/4/25.
//

import Foundation

enum EventCategory: String, Codable {
    case all
    case sports
    case entertainment
    case education
    case music
    case community
    
    var iconName: String {
        switch self {
        case .all:
            return "square.grid.2x2.fill"
        case .sports:
            return "sportscourt.fill"
        case .entertainment:
            return "film.fill"
        case .education:
            return "book.fill"
        case .music:
            return "music.note.list"
        case .community:
            return "person.3.fill"
        }
    }
    
    var title: String {
        switch self {
        case .all: return "All"
        case .sports: return "Sports"
        case .entertainment: return "Entertainment"
        case .education: return "Education"
        case .music: return "Music"
        case .community: return "Community"
        }
    }
}
