import SwiftUI
import TokTokCore

/// 하루 문자판: 사용자가 정한 경계를 12시 방향에 두고 다음 경계까지를 한 바퀴로 그린 시계.
///
/// - 테두리 눈금: 매시 짧게, 6시간마다 길게 + 시 라벨
/// - 지난 시간: 경계부터 지금까지 호박색 호
/// - 기록: 바깥 테두리의 세로 눈금, 가장 최근 기록만 호박색
/// - 바늘: 지금 시각
///
/// 새 데이터를 만들지 않고 이미 화면에 있는 구간·기록 시각을 그림으로 옮긴 것이다.
/// 같은 정보가 헤더 문구와 블록 목록에 있으므로 VoiceOver에서는 숨긴다.
struct DayDialView: View {
    let interval: RecordDayInterval
    /// 시간순(과거 → 최신)
    let records: [Date]
    let timeZone: TimeZone

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            Canvas { ctx, size in
                draw(in: &ctx, size: size, now: context.date)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private var hours: Int { max(Int((interval.duration / 3600).rounded()), 1) }

    private func fraction(_ date: Date) -> Double {
        guard interval.duration > 0 else { return 0 }
        return date.timeIntervalSince(interval.start) / interval.duration
    }

    /// 0 = 12시 방향, 시계 방향
    private func point(_ f: Double, radius: CGFloat, center: CGPoint) -> CGPoint {
        let a = f * 2 * .pi - .pi / 2
        return CGPoint(x: center.x + radius * cos(a), y: center.y + radius * sin(a))
    }

    private func draw(in ctx: inout GraphicsContext, size: CGSize, now: Date) {
        let side = min(size.width, size.height)
        let c = CGPoint(x: size.width / 2, y: size.height / 2)
        let outer = side / 2 - 1
        let face = outer - 8          // 문자판 테두리
        let tickOuter = face - 4
        let labelR = face - 22

        // 문자판 면: 같은 회색 안에서만 아주 약한 밝기 차
        let faceRect = CGRect(x: c.x - face, y: c.y - face, width: face * 2, height: face * 2)
        ctx.fill(Path(ellipseIn: faceRect),
                 with: .radialGradient(Gradient(colors: [Color(white: 0.13), Color(white: 0.085)]),
                                       center: CGPoint(x: c.x, y: c.y - face * 0.4),
                                       startRadius: 0, endRadius: face * 1.3))
        ctx.stroke(Path(ellipseIn: faceRect), with: .color(Theme.hairline), lineWidth: 1)

        // 바깥 기록 트랙
        let trackRect = CGRect(x: c.x - outer + 2, y: c.y - outer + 2, width: (outer - 2) * 2, height: (outer - 2) * 2)
        ctx.stroke(Path(ellipseIn: trackRect), with: .color(Theme.hairline), lineWidth: 1)

        // 지난 시간 호
        let nowF = min(max(fraction(now), 0), 1)
        if nowF > 0 {
            var arc = Path()
            arc.addArc(center: c, radius: outer - 2,
                       startAngle: .radians(-.pi / 2),
                       endAngle: .radians(nowF * 2 * .pi - .pi / 2), clockwise: false)
            ctx.stroke(arc, with: .color(Theme.accent.opacity(0.35)),
                       style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }

        // 시간 눈금
        for h in 0..<hours {
            let f = Double(h) / Double(hours)
            let long = h % 6 == 0
            var p = Path()
            p.move(to: point(f, radius: tickOuter, center: c))
            p.addLine(to: point(f, radius: tickOuter - (long ? 8 : 4), center: c))
            ctx.stroke(p, with: .color(Theme.mutedText.opacity(long ? 0.9 : 0.45)),
                       style: StrokeStyle(lineWidth: long ? 1.5 : 1, lineCap: .round))
        }

        // 시 라벨(6시간마다)
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = timeZone
        f.dateFormat = "HH"
        for h in stride(from: 0, to: hours, by: 6) {
            let date = interval.start.addingTimeInterval(Double(h) * 3600)
            let text = Text(f.string(from: date))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(h == 0 ? Theme.secondaryText : Theme.mutedText)
            ctx.draw(text, at: point(Double(h) / Double(hours), radius: labelR, center: c))
        }

        // 기록 눈금(바깥 트랙)
        for (i, date) in records.enumerated() {
            let rf = fraction(date)
            guard rf >= 0, rf <= 1 else { continue }
            let newest = i == records.count - 1
            var p = Path()
            p.move(to: point(rf, radius: outer + 1, center: c))
            p.addLine(to: point(rf, radius: face - (newest ? 6 : 2), center: c))
            ctx.stroke(p, with: .color(newest ? Theme.accent : Theme.text.opacity(0.8)),
                       style: StrokeStyle(lineWidth: newest ? 2.5 : 1.5, lineCap: .round))
        }

        // 바늘(지금)
        if fraction(now) >= 0, fraction(now) <= 1 {
            var hand = Path()
            hand.move(to: point(nowF + 0.5, radius: 6, center: c))
            hand.addLine(to: point(nowF, radius: labelR - 10, center: c))
            ctx.stroke(hand, with: .color(Theme.text),
                       style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        }
        let hub = CGRect(x: c.x - 3.5, y: c.y - 3.5, width: 7, height: 7)
        ctx.fill(Path(ellipseIn: hub), with: .color(Theme.accent))
        ctx.stroke(Path(ellipseIn: hub), with: .color(Color.black.opacity(0.4)), lineWidth: 1)
    }
}
