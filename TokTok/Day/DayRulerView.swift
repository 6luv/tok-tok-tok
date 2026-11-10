import SwiftUI
import TokTokCore

/// 하루 눈금: 사용자가 정한 경계부터 다음 경계까지를 한 줄 눈금으로 보여 주고,
/// 기록마다 짧은 세로선을 찍는다. 가장 최근 기록만 강조색이다.
///
/// 새 데이터를 만들지 않고 이미 화면에 있는 구간·기록 시각을 그림으로 옮긴 것이다.
/// 같은 정보가 헤더 구간 문구와 블록 목록에 있으므로 VoiceOver에서는 숨긴다.
struct DayRulerView: View {
    let interval: RecordDayInterval
    /// 시간순(과거 → 최신)
    let records: [Date]
    let timeZone: TimeZone

    private let tickArea: CGFloat = 20
    private let labelGap: CGFloat = 4

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            VStack(spacing: labelGap) {
                Canvas { ctx, size in draw(in: &ctx, size: size, now: context.date) }
                    .frame(height: tickArea)
                labels
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: 그리기

    private func fraction(_ date: Date) -> CGFloat {
        guard interval.duration > 0 else { return 0 }
        return CGFloat(date.timeIntervalSince(interval.start) / interval.duration)
    }

    private func draw(in ctx: inout GraphicsContext, size: CGSize, now: Date) {
        let w = size.width
        let baseY = size.height - 2

        func line(_ x: CGFloat, from y0: CGFloat, to y1: CGFloat, _ color: Color, _ width: CGFloat) {
            var p = Path()
            p.move(to: CGPoint(x: x, y: y0))
            p.addLine(to: CGPoint(x: x, y: y1))
            ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
        }

        // 기준선
        var base = Path()
        base.move(to: CGPoint(x: 0, y: baseY))
        base.addLine(to: CGPoint(x: w, y: baseY))
        ctx.stroke(base, with: .color(Theme.mutedText.opacity(0.35)), lineWidth: 1)

        // 지나온 부분
        let nowF = min(max(fraction(now), 0), 1)
        if nowF > 0 {
            var past = Path()
            past.move(to: CGPoint(x: 0, y: baseY))
            past.addLine(to: CGPoint(x: w * nowF, y: baseY))
            ctx.stroke(past, with: .color(Theme.secondaryText.opacity(0.8)), lineWidth: 1)
        }

        // 시간 눈금: 매시 짧게, 6시간마다 길게
        let hours = Int((interval.duration / 3600).rounded())
        if hours > 0 {
            for h in 0...hours {
                let x = w * CGFloat(h) / CGFloat(hours)
                let long = h % 6 == 0
                line(x, from: baseY, to: baseY - (long ? 6 : 3), Theme.mutedText.opacity(long ? 0.7 : 0.4), 1)
            }
        }

        // 기록 눈금
        for (i, date) in records.enumerated() {
            let f = fraction(date)
            guard f >= 0, f <= 1 else { continue }
            let newest = i == records.count - 1
            let x = min(max(w * f, 1), w - 1)
            line(x, from: baseY, to: 2, newest ? Theme.tick : Theme.text.opacity(0.75), newest ? 2 : 1.5)
        }

        // 지금 위치
        if fraction(now) >= 0, fraction(now) <= 1 {
            let dot = CGRect(x: w * nowF - 2.5, y: baseY - 2.5, width: 5, height: 5)
            ctx.fill(Path(ellipseIn: dot), with: .color(Theme.text))
        }
    }

    // MARK: 라벨

    private var labelDates: [(CGFloat, String)] {
        let hours = Int((interval.duration / 3600).rounded())
        guard hours > 0 else { return [] }
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = timeZone
        f.dateFormat = "HH:mm"
        return stride(from: 0, through: hours, by: 6).map { h in
            let date = interval.start.addingTimeInterval(Double(h) * 3600)
            return (CGFloat(h) / CGFloat(hours), f.string(from: date))
        }
    }

    private var labels: some View {
        GeometryReader { geo in
            let items = labelDates
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                let alignment: Alignment = index == 0 ? .leading : (item.0 >= 0.999 ? .trailing : .center)
                Text(item.1)
                    .font(.system(size: 11, weight: .medium, design: .rounded).monospacedDigit())
                    .foregroundStyle(Theme.mutedText)
                    .fixedSize()
                    .frame(width: 60, alignment: alignment)
                    .position(x: labelX(item.0, width: geo.size.width, alignment: alignment), y: geo.size.height / 2)
            }
        }
        .frame(height: 16)
    }

    private func labelX(_ f: CGFloat, width: CGFloat, alignment: Alignment) -> CGFloat {
        switch alignment {
        case .leading: return 30
        case .trailing: return width - 30
        default: return width * f
        }
    }
}
