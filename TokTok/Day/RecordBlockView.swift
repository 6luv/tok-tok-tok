import SwiftUI
import TokTokCore

/// 전체 콘텐츠 폭 블록. 내부 여백 좌우 20pt·상하 16pt, 고정 높이 없음(Dynamic Type).
///
/// 시·분은 본문색, 초는 보조색으로 나눠 탁상시계처럼 읽히게 한다.
/// 가장 최근 블록에는 왼쪽 끝에 강조색 눈금을 둔다(하루 눈금의 강조 눈금과 같은 의미).
struct RecordBlockView: View {
    let block: RecordBlock
    var isNewest = false

    @ScaledMetric(relativeTo: .largeTitle) private var timeSize: CGFloat = 32
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 12))

        layout {
            time
            if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 0) }
            Text(block.dateText)
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Theme.surface)
        .overlay(alignment: .leading) {
            if isNewest {
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 3)
                    .padding(.vertical, 16)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(block.accessibilityLabel)
    }

    /// "03:15" + ":08"
    private var time: some View {
        let parts = Self.split(block.timeText)
        return (Text(parts.main).foregroundStyle(Theme.text)
                + Text(parts.seconds).foregroundStyle(Theme.secondaryText))
            .font(.system(size: timeSize, weight: .regular).monospacedDigit())
    }

    static func split(_ text: String) -> (main: String, seconds: String) {
        // DayPresentation 형식 "HH:mm:ss". 형식이 다르면 나누지 않는다.
        guard text.count == 8, let idx = text.lastIndex(of: ":") else { return (text, "") }
        return (String(text[..<idx]), String(text[idx...]))
    }
}
