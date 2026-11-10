import SwiftUI

/// 앱 안 기록 완료 토스트. 단축어 결과에는 쓰지 않는다(iOS 실행 표시와 겹치지 않게, 2026-11-10).
/// 소리는 내지 않는다(사용자 결정 2026-11-10: 새벽에 울리면 안 됨).
/// 튀어나온 둥근 카드 + 메인 색 눈금 + 얇은 둥근 시각 숫자.
struct RecordToastView: View {
    let date: Date
    @Environment(\.tokTokAccent) private var accent

    var body: some View {
        HStack(spacing: 12) {
            Capsule()
                .fill(accent.tick)
                .frame(width: 3, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                let t = Self.time.string(from: date)
                (Text(t.prefix(5)).foregroundStyle(Theme.text)
                 + Text(t.dropFirst(5)).foregroundStyle(Theme.secondaryText))
                    .font(.system(.title2, design: .rounded).weight(.light).monospacedDigit())
                Text("\(Self.day.string(from: date)) 기록했어요")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer(minLength: 0)
            Image(systemName: "checkmark")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.secondaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Self.spoken.string(from: date)) 기록했어요")
    }

    private static func formatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = format
        return f
    }

    // 매번 만들어 현재 기기 시간대를 따른다(토스트는 드물게 그려진다).
    private static var time: DateFormatter { formatter("HH:mm:ss") }
    private static var day: DateFormatter { formatter("M월 d일") }
    private static var spoken: DateFormatter { formatter("a h시 m분 s초") }
}
