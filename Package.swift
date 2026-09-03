// swift-tools-version: 6.2
import PackageDescription

// The wire contract between the Andon app and `andon-relay` (D-0175 Q3):
// the only types that cross the network, and nothing else. No dependency,
// Foundation only, so the relay builds it on Linux and the widgets decode
// exactly what the relay encodes.
let package = Package(
    name: "RelayContract",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(name: "RelayContract", targets: ["RelayContract"]),
    ],
    targets: [
        .target(name: "RelayContract"),
        .testTarget(name: "RelayContractTests", dependencies: ["RelayContract"]),
    ]
)
