// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Swifw",
    dependencies: [
        .package(name: "Socket", url: "https://github.com/IBM-Swift/BlueSocket.git", from: "1.0.52"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.4.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Swifw",
            dependencies: [
                "Socket",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
        .testTarget(
            name: "SwifwTests",
            dependencies: ["Swifw"]),
    ]
)
