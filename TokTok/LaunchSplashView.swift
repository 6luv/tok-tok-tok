import SwiftUI

/// 앱을 처음 열 때 보이는 로딩 화면(사용자 요청 2026-11-11: 검은 화면 대신).
/// iOS 시작 화면(Info.plist `UILaunchScreen`: LaunchBackground + LaunchLogo)과 같은 모습으로 이어 붙인 뒤,
/// 짧게 머물렀다가 흐려지며 하루 화면을 보여 준다. 자료를 읽는 동안 하루 화면은 뒤에서 이미 준비된다.
struct LaunchSplashView: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 20) {
                Image("LaunchLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                Text("TokTokTok")
                    .font(.system(.title3, design: .rounded).weight(.medium))
                    .foregroundStyle(Theme.secondaryText)
            }
            // 시작 화면 로고와 같은 자리(가운데)에 로고가 오도록 글자 높이만큼 올린다
            .offset(y: 24)
        }
        // 시작 화면 로고는 안전 영역과 상관없이 화면 정가운데에 놓이므로 같이 맞춘다
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("TokTokTok 불러오는 중")
    }
}
