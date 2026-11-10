import SwiftUI

@main
struct TokTokApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark) // Q11 잠정: 다크 기본, 테마 선택 없음
                .tint(Theme.accent)
        }
    }
}
