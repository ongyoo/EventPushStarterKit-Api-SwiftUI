//
//  TestSupport.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

___FILEHEADER___

import Foundation
import UIKit
@testable import Features

// Shared test doubles for every feature test (one module = one namespace,
// so shared helpers live here instead of being redeclared per file).

struct StubError: LocalizedError {
    var errorDescription: String? { "Stub failure" }
}

/// Puts a view controller in a real window so SwiftUI bodies are evaluated.
@MainActor
func render(_ viewController: UIViewController) {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.rootViewController = viewController
    window.makeKeyAndVisible()
    viewController.view.layoutIfNeeded()
}
