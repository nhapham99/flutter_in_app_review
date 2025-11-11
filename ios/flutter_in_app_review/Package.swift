// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "flutter_in_app_review",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(
            name: "flutter_in_app_review",
            targets: ["flutter_in_app_review"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "flutter_in_app_review",
            dependencies: [],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
