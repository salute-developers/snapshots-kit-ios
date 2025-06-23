// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SDSnapshots",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(name: "SDSnapshots", targets: ["SDSnapshots"]),
    ],
    targets: [
        .target(
            name: "SDSnapshots",
            path: "Sources",
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
