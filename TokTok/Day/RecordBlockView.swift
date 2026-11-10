import SwiftUI
import TokTokCore

/// 기록 목록의 한 행. 목록 전체가 파인 판 하나(`DayView.recordList`)에 담기고,
/// 행은 시각과 날짜를 한 면에 함께 담는다(사용자 결정 2026-11-10, 시안 H).
///
/// - 시각은 얇은 둥근 글꼴(SF Pro Rounded 300). 초는 보조색으로 낮춰 시·분이 먼저 읽히게 한다.
/// - 가장 최근 행만 판 안에서 튀어나오고(extruded), 행 안쪽 왼쪽에 호박색 눈금이 있다.
/// - 날짜는 같은 달력 날짜 묶음의 맨 위 행에만 보인다(`RecordBlock.showsDate`). VoiceOver는 늘 날짜를 함께 읽는다.
struct RecordBlockView: View {
    let block: RecordBlock
    var isNewest = false

    @ScaledMetric(relativeTo: .largeTitle) private var digitSize: CGFloat = 32
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    static let cornerRadius: CGFloat = 16

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 12))
        let shape = RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)

        layout {
            time
            if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 0) }
            if block.showsDate { date }
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        // 눈금 자리를 모든 행에 똑같이 두어 시각 시작선을 맞춘다
        .padding(.leading, 24)
        .padding(.trailing, 16)
        .padding(.vertical, 10)
        .background {
            if isNewest { Color.clear.extruded(shape, depth: 5) }
        }
        .overlay(alignment: .leading) {
            if isNewest {
                Capsule()
                    .fill(Theme.tick)
                    .frame(width: 3)
                    .padding(.vertical, 18)
                    .padding(.leading, 10)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(block.accessibilityLabel)
    }

    /// 오른쪽 날짜: "10일" 크게, "11월 · 화" 작게.
    private var date: some View {
        VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: 2) {
            Text(block.dayText)
                .font(.title3)
                .foregroundStyle(Theme.text)
            Text(block.monthWeekdayText)
                .font(.caption)
                .foregroundStyle(Theme.mutedText)
        }
        .monospacedDigit()
    }

    private var time: some View {
        let parts = Self.split(block.timeText)
        let font = Font.system(size: digitSize, weight: .light, design: .rounded).monospacedDigit()
        // 숫자 폭이 같아도 콜론·글꼴 대체로 달라질 수 있어 자리표시로 폭을 맞춘다
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
