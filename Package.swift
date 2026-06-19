// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "OtplessEventIO",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "OtplessEventIO",
            targets: ["OtplessEventIO"]
        )
    ],
    targets: [
        .target(
            name: "OtplessEventIO",
            path: "Sources/OtplessEventIO"
        ),
        .testTarget(
            name: "OtplessEventIOTests",
            dependencies: ["OtplessEventIO"],
            path: "Tests/OtplessEventIOTests"
        )
    ]
)
