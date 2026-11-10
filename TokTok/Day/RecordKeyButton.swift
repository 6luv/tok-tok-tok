import SwiftUI

/// ‘현재 시간 기록’ 버튼. 탁상시계 위의 스누즈 키처럼 아래 받침이 있는 실제 버튼 모양이다.
///
/// - 윗면: 호박색 한 색 안에서 위가 밝고 아래가 어두운 톤 변화(다른 색상으로 넘어가지 않음)
/// - 받침: 더 어두운 호박색 4pt. 누르면 윗면이 내려가 받침이 거의 사라진다
/// - 안쪽: 지금 시각이 1초마다 흐르고, 누르면 이 시각이 목록에 쌓인다
///
/// 화면에 보이는 흐르는 시각은 안내용이다. 실제 저장 시각은 서비스가 처리 진입 시 한 번 읽는다.
struct RecordKeyButton: View {
    let saving: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RecordKeyLabel(saving: saving)
        }
        .buttonStyle(RecordKeyStyle())
        .accessibilityLabel("현재 시간 기록")
        .accessibilityHint("지금 이 순간의 시각을 저장합니다")
    }
}

private struct RecordKeyLabel: View {
    let saving: Bool

    /// 목록 블록과 같은 24시간 형식 "HH:mm:ss"(현재 기기 시간대)
    private static let clock: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    /// 시간대가 바뀌어도 현재 기기 시간대로 표시한다.
    private static func text(_ date: Date) -> String {
        clock.timeZone = .current
        return clock.string(from: date)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(Self.text(context.date))
                    .font(.title.weight(.medium).monospacedDigit())
            }
            Spacer(minLength: 8)
            if saving {
                ProgressView().tint(Theme.onAccent)
                Text("저장 중…")
                    .font(.subheadline.weight(.semibold))
            } else {
                Text("현재 시간 기록")
                    .font(.subheadline.weight(.semibold))
                Image(systemName: "arrow.down")
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .foregroundStyle(Theme.onAccent)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, minHeight: 72)
    }
}

private struct RecordKeyStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let depth: CGFloat = 4
    private let radius: CGFloat = 18

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        configuration.label
            .background {
                ZStack {
                    // 윗면: 같은 호박색 안의 밝기 변화
                    shape.fill(LinearGradient(colors: [Self.top, Theme.accent, Self.lower],
                                              startPoint: .top, endPoint: .bottom))
                    // 윗가장자리 빛
                    shape.strokeBorder(LinearGradient(colors: [Color.white.opacity(0.45), Color.white.opacity(0)],
                                                      startPoint: .top, endPoint: .center),
                                       lineWidth: 1)
                }
            }
            .offset(y: pressed ? depth - 1 : 0)
            .background {
                // 받침
                shape.fill(Self.ledge)
                    .offset(y: depth)
                    .shadow(color: .black.opacity(0.5), radius: 10, y: 6)
            }
            .padding(.bottom, depth)
            .opacity(isEnabled ? 1 : 0.4)
            .animation(reduceMotion ? nil : Theme.ease(0.12), value: pressed)
    }

    private static let top = Color(red: 0xF7 / 255, green: 0xC8 / 255, blue: 0x7A / 255)
    private static let lower = Color(red: 0xE6 / 255, green: 0xA4 / 255, blue: 0x45 / 255)
    private static let ledge = Color(red: 0xA8 / 255, green: 0x72 / 255, blue: 0x2A / 255)
}
