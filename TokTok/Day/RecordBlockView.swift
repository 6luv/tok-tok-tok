import SwiftUI
import TokTokCore

/// 전체 콘텐츠 폭 블록. 내부 여백 좌우 20pt·상하 16pt, 고정 높이 없음(Dynamic Type).
///
/// 시·분·초를 탁상 플립시계처럼 각각 작은 패널에 담는다. 패널 가운데에는 넘김 판이 갈라지는
/// 가는 선이 있다. 초 패널은 한 단계 낮은 색으로 시·분이 먼저 읽히게 한다.
/// 가장 최근 블록은 패널 테두리와 왼쪽 눈금이 호박색이다(하루 눈금의 강조 눈금과 같은 의미).
struct RecordBlockView: View {
    let block: RecordBlock
    var isNewest = false

    @ScaledMetric(relativeTo: .largeTitle) private var digitSize: CGFloat = 30
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 12))

        layout {
            HStack(spacing: 6) {
                ForEach(Array(Self.parts(block.timeText).enumerated()), id: \.offset) { index, part in
                    FlipPanel(text: part, size: digitSize,
                              dimmed: index == 2, highlighted: isNewest)
                }
            }
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

    /// "03:15:08" → ["03", "15", "08"]. 형식이 다르면 나누지 않는다.
    static func parts(_ text: String) -> [String] {
        let p = text.split(separator: ":").map(String.init)
        return p.count == 3 ? p : [text]
    }
}

/// 플립시계 숫자 패널 하나.
private struct FlipPanel: View {
    let text: String
    let size: CGFloat
    let dimmed: Bool
    let highlighted: Bool

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)
        Text(text)
            .font(.system(size: size, weight: .medium).monospacedDigit())
            .foregroundStyle(dimmed ? Theme.secondaryText : Theme.text)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                // 같은 회색 안에서 위가 약간 밝은 넘김 판
                shape.fill(LinearGradient(colors: [Self.panelTop, Self.panelBottom],
                                          startPoint: .top, endPoint: .bottom))
            }
            .overlay {
                // 가운데 갈라지는 선
                Rectangle()
                    .fill(Color.black.opacity(0.55))
                    .frame(height: 1)
            }
            .overlay {
                shape.strokeBorder(highlighted ? Theme.accent.opacity(0.45) : Theme.hairline, lineWidth: 1)
            }
            .overlay(alignment: .top) {
                // 윗가장자리 빛
                shape.strokeBorder(LinearGradient(colors: [Color.white.opacity(0.10), .clear],
                                                  startPoint: .top, endPoint: .center), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
    }

    private static let panelTop = Color(red: 0x2A / 255, green: 0x2A / 255, blue: 0x2D / 255)
    private static let panelBottom = Color(red: 0x21 / 255, green: 0x21 / 255, blue: 0x23 / 255)
}
