import SwiftUI
import TokTokCore

/// 전체 콘텐츠 폭 블록. 내부 여백 좌우 20pt·상하 12pt, 블록 사이 4pt, 고정 높이 없음(Dynamic Type).
///
/// 시각은 바탕에 파인 홈(inset) 안에 얇은 둥근 글꼴(SF Pro Rounded 300)로 새긴다.
/// 초는 보조색으로 낮춰 시·분이 먼저 읽히게 한다.
/// 가장 최근 블록은 홈이 파이지 않고 튀어나오며(extruded), 왼쪽에 호박색 눈금이 있다.
struct RecordBlockView: View {
    let block: RecordBlock
    var isNewest = false

    @ScaledMetric(relativeTo: .largeTitle) private var digitSize: CGFloat = 32
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 12))
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        layout {
            time
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .modifier(Well(raised: isNewest, shape: shape))
            if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 0) }
            Text(block.dateText)
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Theme.surface)
        .overlay(alignment: .leading) {
            if isNewest {
                Capsule()
                    .fill(Theme.tick)
                    .frame(width: 3)
                    .padding(.vertical, 20)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(block.accessibilityLabel)
    }

    private var time: some View {
        let parts = Self.split(block.timeText)
        let font = Font.system(size: digitSize, weight: .light, design: .rounded).monospacedDigit()
        // 숫자 폭이 같아도 콜론·글꼴 대체로 달라질 수 있어 자리표시로 창 폭을 맞춘다
        return ZStack(alignment: .leading) {
            Text("00:00:00").font(font).hidden()
            (Text(parts.main).foregroundStyle(Theme.text)
             + Text(parts.seconds).foregroundStyle(Theme.secondaryText))
                .font(font)
        }
    }

    /// "03:15:08" → ("03:15", ":08"). 형식이 다르면 나누지 않는다.
    static func split(_ text: String) -> (main: String, seconds: String) {
        guard text.count == 8, let idx = text.lastIndex(of: ":") else { return (text, "") }
        return (String(text[..<idx]), String(text[idx...]))
    }
}

private struct Well<S: Shape>: ViewModifier {
    let raised: Bool
    let shape: S

    func body(content: Content) -> some View {
        if raised {
            content.extruded(shape, depth: 5)
        } else {
            content.inset(shape, depth: 3)
        }
    }
}
