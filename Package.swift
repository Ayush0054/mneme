// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Mneme",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Mneme", targets: ["Mneme"])],
    targets: [.executableTarget(name: "Mneme", linkerSettings: [
        .linkedFramework("AppKit"), .linkedFramework("ApplicationServices"),
        .linkedFramework("Carbon"), .linkedFramework("Security"), .linkedFramework("CoreText")
    ])]
)
