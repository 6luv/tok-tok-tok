import SwiftUI

/// 개인정보처리방침 전문(사용자 결정 2026-11-11: 앱 안에는 웹 링크 대신 전문을 넣는다).
/// 내용은 App Store Connect에 등록하는 웹 페이지(`site/privacy/index.html`)와 같아야 한다.
/// 한쪽을 고치면 다른 쪽과 시행일도 함께 고친다.
struct PrivacyPolicyView: View {
    static let effectiveDate = "2026년 11월 11일"
    static let contactEmail = "toktoktok.support@gmail.com"

    var body: some View {
        NeuPage {
            VStack(alignment: .leading, spacing: 8) {
                Text("시행일 \(Self.effectiveDate)")
                    .font(.footnote)
                    .foregroundStyle(Theme.mutedText)
                Text("TokTokTok(이하 ‘앱’)은 뒷면 탭·단축어·버튼으로 지금 시각을 기록하는 iPhone 앱입니다. 이 방침은 앱이 다루는 정보와 그 처리 방식을 설명합니다.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 4)

            clause("요약", [
                "앱은 개인정보를 수집하지 않으며 개발자에게 아무것도 보내지 않습니다.",
                "기록과 설정은 사용자의 iPhone에 저장됩니다. 사용자가 켠 iCloud·컴퓨터 백업에는 포함될 수 있습니다.",
                "계정, 서버, 광고, 분석 도구를 쓰지 않습니다.",
            ])
            clause("1. 수집하는 개인정보", [
                "앱은 이름, 이메일, 전화번호, 위치, 기기 식별자 등 어떤 개인정보도 수집하지 않습니다. 회원 가입이나 로그인 기능이 없습니다.",
            ])
            clause("2. 기기 안에 저장되는 정보", [
                "앱이 동작하기 위해 아래 정보를 사용자의 기기에 저장합니다. 앱은 이 정보를 개발자나 다른 서버로 보내지 않습니다. 기기 백업은 4조를 참고하세요.",
                "시간 기록: 기록마다 붙는 임의 식별자(기기 식별자가 아님), 기록한 시각, 기록 당시 시간대와 UTC 오프셋, 기록 방법(앱 안 버튼, 또는 단축어·뒷면 탭·Siri처럼 단축어 동작으로 실행), 저장 형식 버전",
                "앱 설정: 하루 시작 시간, 설정 형식 버전, 화면 모드, 메인 색, 진동 켜기·끄기",
            ])
            clause("3. 제3자 제공과 처리 위탁", [
                "앱은 정보를 외부로 보내지 않으므로 제3자 제공이나 처리 위탁이 없습니다. 광고·분석·추적 도구를 포함하지 않습니다.",
            ])
            clause("4. 백업과 Apple 기능", [
                "iCloud 백업이나 컴퓨터 백업을 켜 두면 앱의 기록이 Apple의 정책에 따라 백업에 포함될 수 있습니다.",
                "뒷면 탭, 단축어, Siri로 기록할 때 해당 기능은 iOS가 실행하며, 그 처리에는 Apple의 개인정보 처리방침이 적용됩니다. 앱이 받는 것은 ‘지금 기록하라’는 실행 요청뿐입니다.",
            ])
            clause("5. 보관 기간과 삭제", [
                "기록은 사용자가 지울 때까지 기기에 보관됩니다. 앱이 자동으로 지우지 않습니다.",
                "하루 화면에서 기록을 오른쪽으로 밀면 그 기록 하나를 지울 수 있습니다.",
                "앱의 설정 > ‘오늘 기록 지우기’로 현재 하루의 기록을 한꺼번에 지울 수 있습니다.",
                "앱을 삭제하면 기기 안의 기록과 설정이 모두 함께 삭제됩니다. 백업에 남은 사본은 iCloud 백업 설정 또는 백업을 만든 컴퓨터의 백업 관리 기능에서 따로 관리·삭제합니다.",
            ])
            clause("6. 아동의 개인정보", [
                "앱은 누구의 개인정보도 수집하지 않으므로 아동의 개인정보도 수집하지 않습니다.",
            ])
            clause("7. 방침의 변경", [
                "앱의 기능이 바뀌어 이 방침을 고칠 때는 앱 업데이트와 웹 페이지에 변경 내용과 새 시행일을 알립니다.",
            ])

            NeuSection {
                VStack(alignment: .leading, spacing: 4) {
                    if let mail = URL(string: "mailto:\(Self.contactEmail)") {
                        Link(destination: mail) {
                            Label(Self.contactEmail, systemImage: "envelope")
                                .font(.subheadline.weight(.medium))
                                .frame(minHeight: 44, alignment: .leading)
                        }
                        .foregroundStyle(.tint)
                        .accessibilityHint("메일 앱에서 문의 메일을 써요")
                    }
                }
            } header: {
                Text("8. 문의")
            }
        }
        .neuNavigation(title: "개인정보처리방침")
    }

    private func clause(_ title: String, _ items: [String]) -> some View {
        NeuSection {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } header: {
            Text(title)
        }
    }
}
