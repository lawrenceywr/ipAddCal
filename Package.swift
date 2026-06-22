// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "IPNetworkCalculator",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(name: "IPCalculatorCore", targets: ["IPCalculatorCore"]),
        .library(name: "IPCalculatorFeatures", targets: ["IPCalculatorFeatures"]),
        .executable(name: "IPNetworkCalculator", targets: ["IPNetworkCalculator"])
    ],
    targets: [
        .target(name: "IPCalculatorCore"),
        .target(name: "IPCalculatorFeatures", dependencies: ["IPCalculatorCore"]),
        .executableTarget(
            name: "IPNetworkCalculator",
            dependencies: ["IPCalculatorFeatures", "IPCalculatorCore"]
        ),
        .testTarget(name: "IPCalculatorCoreTests", dependencies: ["IPCalculatorCore"]),
        .testTarget(name: "IPCalculatorFeaturesTests", dependencies: ["IPCalculatorFeatures", "IPCalculatorCore"]),
        .testTarget(name: "IPNetworkCalculatorTests", dependencies: ["IPNetworkCalculator"])
    ]
)
