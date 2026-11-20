// swift-tools-version: 6.2
import PackageDescription

// 12.19.3 is the newest 12.x patch and retains Firebase's iOS 26 hybrid API.
// Firebase 13.x's replacement uses iOS 27 Foundation Models APIs; see docs/PLATFORMS.md.
let package = Package(
    name: "MeetHalfway",
    platforms: [.iOS(.v17)],
    products: [.library(name: "MeetHalfway", type: .dynamic, targets: ["MeetHalfway"])],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", exact: "12.19.3")
    ],
    targets: [
        .target(
            name: "MeetHalfway",
            dependencies: [
                .product(name: "FirebaseAILogic", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAppCheck", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk")
            ],
            path: "Sources/MeetHalfway",
            linkerSettings: [.unsafeFlags(["-ObjC"])]
        )
    ],
    swiftLanguageModes: [.v5]
)
