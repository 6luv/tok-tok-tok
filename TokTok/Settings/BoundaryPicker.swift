import SwiftUI
import TokTokCore

/// 시·분 선택기(00:00~23:59)와 선택값에 따른 실제 구간 예시.
struct BoundaryPicker: View {
    @Binding var hour: Int
    @Binding var minute: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                Picker("시", selection: $hour) {
                    ForEach(0..<24, id: \.self) { Text(String(format: "%02d시", $0)).tag($0) }
                }
                .pickerStyle(.wheel)
                .accessibilityLabel("시")
                Picker("분", selection: $minute) {
                    ForEach(0..<60, id: \.self) { Text(String(format: "%02d분", $0)).tag($0) }
                }
                .pickerStyle(.wheel)
                .accessibilityLabel("분")
            }
            .frame(maxHeight: 180)

            if let boundary = DayBoundary(hour: hour, minute: minute) {
                Text(BoundaryExample.text(for: boundary))
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

enum BoundaryExample {
    /// "지금 구간 10/31 23:00 – 11/01 23:00\n23:00 전 기록은 전날로 묶여요"
    static func text(for boundary: DayBoundary, now: Date = Date(), timeZone: TimeZone = .current) -> String {
        let calc = DayBoundaryCalculator(boundary: boundary, timeZone: timeZone)
        let interval = calc.interval(for: calc.recordDay(containing: now))
        let p = DayPresentation(timeZone: timeZone)
        let b = DayPresentation.boundaryText(boundary)
        if boundary.minutes == 0 {
            return "지금 구간 \(p.rangeText(for: interval))\n달력 날짜와 같아요"
        }
        return "지금 구간 \(p.rangeText(for: interval))\n\(b) 전 기록은 전날로 묶여요"
    }
}
