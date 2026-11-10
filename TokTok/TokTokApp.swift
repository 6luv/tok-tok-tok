import SwiftUI

@main
struct TokTokApp: App {
    /// Q11 결정(2026-11-10): 설정에서 다크·라이트 선택, 기본 다크
    @AppStorage(AppAppearance.storageKey) private var appearance: AppAppearance = .dark

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(appearance.colorScheme)
                .tint(Theme.accent)
        }
    }
}
