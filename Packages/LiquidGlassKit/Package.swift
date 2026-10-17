// swift-tools-version: 6.0
//
//  Package.swift
//  LiquidGlassKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import PackageDescription

// iOS 26 Liquid Glass for iOS 17+: a glass view and a drop-in tab bar.
// No dependencies, public UIKit API only.
let package = Package(
    name: "LiquidGlassKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "LiquidGlassKit", targets: ["LiquidGlassKit"]),
    ],
    targets: [
        .target(name: "LiquidGlassKit"),
        .testTarget(name: "LiquidGlassKitTests", dependencies: ["LiquidGlassKit"]),
    ]
)
