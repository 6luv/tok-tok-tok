import SwiftUI

/// 앱 내 개인정보 안내(App Review 가이드라인의 앱 내 접근 경로 준비용).
/// 외부 개인정보처리방침 URL은 제출 전에 확정해 연결해야 한다.
struct PrivacyInfoView: View {
    var body: some View {
        List {
            Section {
                Text("TokTok은 계정, 서버, 광고, 분석 도구를 사용하지 않아요.")
                Text("기록한 시각과 시간대 정보, 하루 시작 시간 설정은 이 기기의 앱 저장 공간에만 저장되고 개발자에게 전송되지 않아요.")
                Text("다만 iCloud 백업이나 컴퓨터 백업을 켜 두었다면 기기 백업에 함께 포함될 수 있어요.")
                Text("앱을 삭제하면 이 기기에 있는 기록도 함께 삭제돼요.")
            }
            .font(.subheadline)
            .foregroundStyle(Theme.text)
            .listRowBackground(Theme.surface)
        }
        .tokTokListStyle()
        .navigationTitle("개인정보와 데이터")
        .navigationBarTitleDisplayMode(.inline)
    }
}
