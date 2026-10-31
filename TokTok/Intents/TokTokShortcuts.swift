import AppIntents

/// 단축어 앱에 바로 보이는 App Shortcut. 사용자는 이 단축어를 뒷면 탭에 직접 연결한다(R03).
/// 앱이 뒷면 탭 설정을 바꾸거나 연결 여부를 확인하지는 않는다.
struct TokTokShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RecordNowIntent(),
            phrases: [
                "\(.applicationName)로 현재 시간 기록",
                "\(.applicationName) 기록",
            ],
            shortTitle: "현재 시간 기록",
            systemImageName: "clock.badge.checkmark"
        )
    }
}
