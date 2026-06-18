// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FFmpegFreeSwiftUI",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "FFmpegFreeSwiftUI", targets: ["FFmpegFreeSwiftUI"]),
        .executable(name: "FFmpegFreeSwiftUIApp", targets: ["FFmpegFreeSwiftUIApp"]),
        .executable(name: "FFmpegFreeSwiftUITestRunner", targets: ["FFmpegFreeSwiftUITestRunner"])
    ],
    targets: [
        .target(
            name: "FFmpegFreeSwiftUI",
            path: "Sources/FFmpegFreeSwiftUI"
        ),
        .target(
            name: "FFmpegFreeSwiftUITestSupport",
            dependencies: ["FFmpegFreeSwiftUI"],
            path: "Sources/FFmpegFreeSwiftUITestSupport"
        ),
        .executableTarget(
            name: "FFmpegFreeSwiftUIApp",
            dependencies: ["FFmpegFreeSwiftUI"],
            path: "Sources/FFmpegFreeSwiftUIApp",
            exclude: [
                "Resources/Info.plist"
            ],
            resources: [
                .copy("Resources/AppIcon.icns")
            ]
        ),
        .executableTarget(
            name: "FFmpegFreeSwiftUITestRunner",
            dependencies: ["FFmpegFreeSwiftUITestSupport"],
            path: "Sources/FFmpegFreeSwiftUITestRunner"
        )
    ]
)
