// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PerformanceBezier",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "PerformanceBezier",
            targets: ["PerformanceBezier"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "PerformanceBezier",
            dependencies: [],
            path: "PerformanceBezier",
            exclude: ["Info.plist", "PerformanceBezier-Info.plist"],
            publicHeadersPath: "."),
        .testTarget(
            name: "PerformanceBezierTests",
            dependencies: ["PerformanceBezier"]),
    ]
)
