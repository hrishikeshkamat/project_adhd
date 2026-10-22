// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SessionCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "SessionCore", targets: ["SessionCore"]),
        .executable(name: "sessionboard-cli", targets: ["sessionboard-cli"]),
    ],
    targets: [
        .target(name: "SessionCore"),
        .executableTarget(name: "sessionboard-cli", dependencies: ["SessionCore"]),
        .testTarget(name: "SessionCoreTests", dependencies: ["SessionCore"]),
    ]
)
