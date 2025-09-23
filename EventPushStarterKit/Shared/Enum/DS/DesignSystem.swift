//
//  DesignSystem.swift
//  EventPush
//
//  Created by Nathat Kuanthanom on 9/10/25.
//

import Foundation

enum DS {
  enum Space: CGFloat, CaseIterable {
    case xxs = 4
    case xs = 8
    case s = 12
    case m = 16
    case l = 20
    case xl = 24
    case xxl = 32
    case xxxl = 48
    case ultra = 64
  }

  enum Radius: CGFloat {
    case s = 8, m = 12, l = 16, xl = 24
  }
}
