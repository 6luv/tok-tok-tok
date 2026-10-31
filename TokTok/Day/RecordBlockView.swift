import SwiftUI
import TokTokCore

/// 전체 콘텐츠 폭 블록. 내부 여백만 좌우 20pt·상하 16pt, 고정 높이 없음(Dynamic Type).
struct RecordBlockView: View {
    let block: RecordBlock
    @ScaledMetric(relativeTo: .largeTitle) private var timeSize: CGFloat = 30
    @ScaledMetric(relativeTo: .footnote) private var dateSize: CGFloat = 13

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(block.timeText)
                .font(.system(size: timeSize, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(Theme.text)
            Text(block.dateText)
                .font(.system(size: dateSize))
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Theme.block)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(block.accessibilityLabel)
    }
}
