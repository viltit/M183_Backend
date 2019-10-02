// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "projektarbeit",
    products: [
        .library(name: "projektarbeit", targets: ["App"]),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),

        // 🔵 Swift ORM (queries, models, relations, etc) built on SQLite 3.
        .package(url: "https://github.com/vapor/fluent-mysql.git", from: "3.0.0"),

         // HTML Templating module
        .package(url: "https://github.com/vapor/leaf.git", from: "3.0.0"),

        // Handles different types of authentication:
        .package(
                url: "https://github.com/vapor/auth.git",
                from: "2.0.0")
    ],
    targets: [
        .target(name: "App", dependencies: ["FluentMySQL", "Vapor", "Leaf", "Authentication"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

