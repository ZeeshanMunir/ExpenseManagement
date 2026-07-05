// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Data",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Data",
            targets: ["Data"]
        )
    ],
    dependencies: [
        .package(path: "../Domain"),
        .package(path: "../Core")
    ],
    targets: [
        .target(
            name: "Data",
            dependencies: [
                "Domain",
                "Core"
            ],
            resources: [
                .process("Local/SmartExpenseManager.xcdatamodeld")
            ]
        )
    ]
)
