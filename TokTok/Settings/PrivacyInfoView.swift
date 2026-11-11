import SwiftUI

/// 앱 내 개인정보 안내(App Review 가이드라인의 앱 내 접근 경로 준비용).
/// 2026-11-11 다시 정리: 한 줄 요약 카드 + 아이콘 행(제목·한 줄 설명).
/// 외부 개인정보처리방침 URL은 배포 주소가 정해지면 ‘더 알아보기’ 카드 맨 아래에 링크 한 줄로 넣는다.
struct PrivacyInfoView: View {
    var body: some View {
        NeuPage {
            summary

            NeuSection {
                PrivacyRow(icon: "iphone", title: "이 기기에만 저장",
                           detail: "기록한 시각과 설정은 이 iPhone 안에만 있어요")
                divider
                PrivacyRow(icon: "person.crop.circle.badge.xmark", title: "계정·서버 없음",
                           detail: "로그인 없이 쓰고, 개발자에게 보내는 데이터가 없어요")
                divider
                PrivacyRow(icon: "chart.bar.xaxis", title: "광고·분석 도구 없음",
                           detail: "사용 기록을 모으거나 추적하지 않아요")
            } header: {
                Text("저장과 전송")
            }

            NeuSection {
                PrivacyRow(icon: "icloud", title: "기기 백업",
                           detail: "iCloud·컴퓨터 백업을 켜 두면 기록도 백업에 포함될 수 있어요")
                divider
                PrivacyRow(icon: "trash", title: "앱 삭제",
                           detail: "앱을 지우면 이 기기에 있는 기록도 함께 지워져요")
                divider
                PrivacyRow(icon: "globe", title: "시간대",
                           detail: "지금 기기 시간대로 보여 주고, 기록 당시 시간대도 함께 보관해요")
                // 개인정보처리방침 링크: 배포 주소가 정해지면 여기 한 줄로 넣는다(tok-tok-a8 담당).
            } header: {
                Text("알아 두세요")
            }
        }
        .neuNavigation(title: "개인정보와 데이터")
    }

    private var summary: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(.tint)
                .frame(width: 52, height: 52)
                .inset(Circle(), depth: 3)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("기록은 이 iPhone에 저장돼요")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text("개발자에게 보내거나 따로 모으지 않아요")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .extruded(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous), depth: 5)
        .accessibilityElement(children: .combine)
    }

    private var divider: some View {
        Theme.hairline.frame(height: 1)
    }
}

/// 개인정보 안내 한 줄: 파인 원 안 아이콘 + 제목 + 한 줄 설명.
private struct PrivacyRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Theme.secondaryText)
                .frame(width: 36, height: 36)
                .inset(Circle(), depth: 2)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.text)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 1)
        }
        .accessibilityElement(children: .combine)
    }
}
