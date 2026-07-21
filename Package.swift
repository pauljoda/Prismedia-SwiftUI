// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PrismediaCore",
    platforms: [
        .iOS("26.0"),
        .macOS("26.0"),
        .tvOS("26.0"),
    ],
    products: [
        .library(
            name: "PrismediaCore",
            targets: ["PrismediaCore"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/mihai8804858/swift-ass-renderer.git",
            exact: "1.3.1"
        ),
        .package(
            url: "https://github.com/readium/swift-toolkit.git",
            exact: "3.10.0"
        ),
    ],
    targets: [
        .target(
            name: "PrismediaCore",
            dependencies: [
                .product(
                    name: "SwiftAssRenderer",
                    package: "swift-ass-renderer",
                    condition: .when(platforms: [.iOS, .macOS, .tvOS])
                ),
                .product(
                    name: "ReadiumShared",
                    package: "swift-toolkit",
                    condition: .when(platforms: [.iOS])
                ),
                .product(
                    name: "ReadiumStreamer",
                    package: "swift-toolkit",
                    condition: .when(platforms: [.iOS])
                ),
                .product(
                    name: "ReadiumNavigator",
                    package: "swift-toolkit",
                    condition: .when(platforms: [.iOS])
                ),
            ],
            path: ".",
            exclude: [
                "AGENTS.md",
                "Carthage",
                "Docs",
                "README.md",
                "Prismedia.xcodeproj",
                "PrismediaAppIcon.icon",
                "PrismediaCloud.xcworkspace",
                "PrismediaCoreTests",
                "PrismediaMac/Info.plist",
                "PrismediaMac/PrismediaMac.entitlements",
                "PrismediaMac/PrismediaMacApp.swift",
                "PrismediaMac/PrismediaMacCommands.swift",
                "PrismediaTV/Assets.xcassets",
                "PrismediaTV/Info.plist",
                "PrismediaTV/PrismediaTV.entitlements",
                "PrismediaTV/PrismediaTVApp.swift",
                "PrismediaTVUITests",
                "PrismediaiOS/Info.plist",
                "PrismediaiOS/PrismediaAppDelegate.swift",
                "PrismediaiOS/PrismediaiOS.entitlements",
                "PrismediaiOS/PrismediaiOSApp.swift",
                "PrismediaiOSUITests",
                "Scripts",
                "XcodeCloudBootstrap",
                "ci_scripts",
                "design-qa.md",
                "v2-icon.icon",
            ],
            sources: [
                "PrismediaShared/App",
                "PrismediaShared/DesignSystem",
                "PrismediaShared/Domain",
                "PrismediaShared/Features",
                "PrismediaShared/Infrastructure",
                "PrismediaShared/Networking",
                "PrismediaShared/Presentation",
                "PrismediaShared/PreviewSupport",
                "PrismediaShared/Storage",
                "PrismediaShared/UI",
                "PrismediaiOS/Features",
                "PrismediaiOS/Infrastructure",
                "PrismediaMac/Features",
                "PrismediaTV/App",
                "PrismediaTV/Features",
                "PrismediaTV/Infrastructure",
            ],
            resources: [
                .process("PrismediaShared/Resources")
            ]
        ),
        .testTarget(
            name: "PrismediaCoreTests",
            dependencies: ["PrismediaCore"],
            path: "PrismediaCoreTests"
        ),
    ]
)
