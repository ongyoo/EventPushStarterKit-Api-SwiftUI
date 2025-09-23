//
//  ViewState.swift
//  EventPush
//
//  Created by Nathat Kuanthanom on 9/10/25.
//

import Foundation

enum ViewState: Equatable {
    case idle
    case loading
    case success
    case error(String)
}
