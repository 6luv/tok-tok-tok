import SwiftUI

/// 앱 내 개인정보 안내(App Review 가이드라인의 앱 내 접근 경로 준비용).
/// 외부 개인정보처리방침 URL은 제출 전에 확정해 연결해야 한다.
struct PrivacyInfoView: View {
    var body: some View {
        NeuPage {
            NeuSection {
                Text("계정·서버·광고·분석 도구를 쓰지 않아요")
                Text("기록과 설정은 이 기기에만 저장되고 개발자에게 보내지 않아요")
                Text("iCloud·컴퓨터 백업을 켜 두면 백업에 포함될 수 있어요")
                Text("앱을 지우면 기록도 함께 지워져요")
                Text("시각은 지금 기기 시간대로 보여요. 기록 당시 시간대도 함께 보관해요.")
            }
            .font(.subheadline)
            .foregroundStyle(Theme.text)
        }
        .navigationTitle("개인정보와 데이터")
        .navigationBarTitleDisplayMode(.inline)
    }
}
