import SwiftUI

struct RootView: View {
    @State private var showsSplash = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // 하루 화면은 처음부터 뒤에서 만들어 자료를 읽는다
            DayView()
            if showsSplash {
                LaunchSplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            // 시작 화면에서 이어지는 로고를 잠깐 보여 준 뒤 흐려진다(모션 감소면 바로 사라짐)
            try? await Task.sleep(nanoseconds: 700_000_000)
            if reduceMotion { showsSplash = false } else {
                withAnimation(Theme.ease(0.35)) { showsSplash = false }
            }
        }
    }
}
