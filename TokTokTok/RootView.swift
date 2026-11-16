import SwiftUI

struct RootView: View {
    @State private var showsSplash = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // 하루 화면은 처음부터 뒤에서 만들어 자료를 읽는다
            DayView()
                // 로딩 화면이 덮고 있는 동안 VoiceOver가 뒤의 하루 화면으로 가지 않게 한다(Codex 검증)
                .accessibilityHidden(showsSplash)
            if showsSplash {
                LaunchSplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            // 시작 화면에서 이어지는 그림을 1.5초 보여 준 뒤 흐려진다(사용자 요청 2026-11-11 ‘조금 더 길게’, 모션 감소면 바로 사라짐)
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            if reduceMotion { showsSplash = false } else {
                withAnimation(Theme.ease(0.45)) { showsSplash = false }
            }
        }
    }
}
