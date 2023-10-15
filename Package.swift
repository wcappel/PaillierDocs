// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let name = "PaillierDocsProject"
let package = Package(
    name: name,
    platforms: [
        .macOS(.v12),
    ],
    dependencies: [
//        .package(url: "https://github.com/code28/SwiftPaillier.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.0"),
        .package(url: "https://github.com/mkrd/Swift-BigInt.git", from: "2.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: name,
            dependencies: [
                /*.product(name: "SwiftPaillier", package: "SwiftPaillier"),*/
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "BigNumber", package: "Swift-BigInt")
            ],
            path: ""
        )
    ]
)
