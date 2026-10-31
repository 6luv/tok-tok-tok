// swift-tools-version:5.9
import PackageDescription

// 플랫폼 독립 도메인 로직(하루 경계 계산, 로컬 저장, 기록 서비스).
// iOS 앱과 App Intent가 공용으로 사용하며, Linux/macOS에서 `swift test`로 검증할 수 있다.
let package = Package(
    name: "TokTokCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "TokTokCore", targets: ["TokTokCore"]),
    ],
    targets: [
        .target(name: "TokTokCore"),
        .testTarget(name: "TokTokCoreTests", dependencies: ["TokTokCore"]),
    ]
)
