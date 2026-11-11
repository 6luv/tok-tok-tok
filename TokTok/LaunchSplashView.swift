import SwiftUI

/// 앱을 처음 열 때 보이는 로딩 화면(사용자 요청 2026-11-11).
/// - 기기·앱 화면 모드와 관계없이 다크(#1B1A18 + 아이보리 선). 앱 아이콘과 같은 색이다.
/// - iOS 시작 화면(Info.plist `UILaunchScreen`: LaunchBackground + LaunchArt)과 같은 그림을 같은 크기·자리로 띄워
///   두 화면이 끊김 없이 이어진다. 그림 안에서 큰 자명종이 오른쪽 아래에 잘려 걸린다.
/// - 위쪽에 ‘TokTokTok’과 한 줄 소개를 붙인다(시작 화면에는 글자를 넣지 않는다).
struct LaunchSplashView: View {
    /// 아이콘 바탕색 #1B1A18 / 선 색 #F2EBD9
    static let background = Color(red: 0x1B / 255, green: 0x1A / 255, blue: 0x18 / 255)
    static let ivory = Color(red: 0xF2 / 255, green: 0xEB / 255, blue: 0xD9 / 255)
    static let ivoryDim = Color(red: 0xBD / 255, green: 0xB5 / 255, blue: 0xA3 / 255)

    var body: some View {
        ZStack(alignment: .topLeading) {
            Self.background.ignoresSafeArea()
            // 시작 화면 그림은 안전 영역과 관계없이 화면 정가운데에 원래 크기로 놓이므로 똑같이 맞춘다
            Image("LaunchArt")
                .resizable()
                .frame(width: 440, height: 956)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 8) {
                Text("TokTokTok")
                    .font(.system(size: 40, weight: .medium, design: .rounded))
                    .foregroundStyle(Self.ivory)
                Text("뒷면을 톡톡톡, 지금 시각을 남겨요")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Self.ivoryDim)
            }
            .padding(.horizontal, 28)
            .padding(.top, 40)
        }
        .environment(\.colorScheme, .dark)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("TokTokTok 불러오는 중")
    }
}
