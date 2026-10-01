// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Tock",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Tock", targets: ["Tock"]),
        .executable(name: "tock-render", targets: ["tock-render"]),
    ],
    targets: [
        .target(name: "TockCore"),
        .executableTarget(name: "Tock", dependencies: ["TockCore"]),
        .executableTarget(name: "tock-render", dependencies: ["TockCore"]),
        .testTarget(name: "TockCoreTests", dependencies: ["TockCore"]),
    ]
)
