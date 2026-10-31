import SwiftUI

/// App Intent 단계의 임시 루트 화면. 하루 화면은 feature/day-screen에서 교체한다.
struct RootView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("TokTok")
                .font(.largeTitle.bold())
            Text("단축어 앱에서 ‘현재 시간 기록’ 액션을 사용할 수 있어요.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
