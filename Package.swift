// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "PartitiUI",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PartitiUI", targets: ["PartitiUI"])
    ],
    targets: [
        .target(name: "PartitiUI", resources: [.process("Resources")]),
        .executableTarget(
            name: "Mockups",
            dependencies: ["PartitiUI"],
            resources: [.copy("Icons")]
        ),
        .testTarget(name: "PartitiUITests", dependencies: ["PartitiUI"])
    ]
)
