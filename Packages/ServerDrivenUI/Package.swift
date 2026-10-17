// swift-tools-version: 6.0
//
//  Package.swift
//  ServerDrivenUI
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import PackageDescription

// Screens described by a backend (BFF) as JSON, rendered as native SwiftUI
// with Liquid Glass components. Versioned schema, safe fallbacks.
let package = Package(
    name: "ServerDrivenUI",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ServerDrivenUI", targets: ["ServerDrivenUI"]),
    ],
    dependencies: [
        .package(path: "../LiquidGlassKit"),
    ],
    targets: [
        .target(name: "ServerDrivenUI", dependencies: ["LiquidGlassKit"]),
        .testTarget(name: "ServerDrivenUITests", dependencies: ["ServerDrivenUI"]),
    ]
)
