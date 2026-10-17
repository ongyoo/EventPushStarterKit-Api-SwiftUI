// swift-tools-version: 6.0
import PackageDescription

// Business logic written once in Swift, shipped to Android as a native library.
//
//   EventShared   Pure Swift (FoundationEssentials only). Builds for macOS, iOS and Android.
//   EventBridge   JNI entry points Kotlin calls. Real code only when building for Android.
//   CJNI          Tiny C shim around <jni.h>.
//
// Android build (see ../scripts/build-swift.sh):
//   swift build --swift-sdk aarch64-unknown-linux-android28 --static-swift-stdlib -c release
// Tests on the Mac:
//   swift test
let package = Package(
    name: "SwiftCore",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "EventShared", targets: ["EventShared"]),
        // Becomes libEventBridge.so, loaded by `System.loadLibrary("EventBridge")`.
        .library(name: "EventBridge", type: .dynamic, targets: ["EventBridge"]),
    ],
    targets: [
        .target(name: "EventShared"),
        .target(name: "CJNI"),
        .target(
            name: "EventBridge",
            dependencies: ["EventShared", "CJNI"],
            linkerSettings: [
                // The Swift concurrency runtime (linked statically) uses libdispatch;
                // --static-swift-stdlib does not add it for library products.
                .linkedLibrary("dispatch", .when(platforms: [.android])),
                .linkedLibrary("BlocksRuntime", .when(platforms: [.android])),
            ]
        ),
        .testTarget(name: "EventSharedTests", dependencies: ["EventShared"]),
    ]
)
