import Foundation

/// 화면 블록 하나.
public struct RecordBlock: Identifiable, Equatable, Sendable {
    public let id: UUID
    /// "03:15:08"
    public let timeText: String
    /// 기록의 실제 달력 날짜 "11월 1일" (기록일 헤더와 다를 수 있음)
    public let dateText: String
    /// 블록 오른쪽 큰 날짜 "1일"
    public let dayText: String
    /// 블록 오른쪽 작은 줄 "11월 · 토"
    public let monthWeekdayText: String
    /// "11월 1일 오전 3시 15분 8초, 시간 기록"
    public let accessibilityLabel: String
}

/// 하루 화면 표시 규칙. 표시 시간대는 현재 기기 시간대(Q03 잠정).
public struct DayPresentation: Sendable {
    public let timeZone: TimeZone
    public let locale: Locale

    public init(timeZone: TimeZone, locale: Locale = Locale(identifier: "ko_KR")) {
        self.timeZone = timeZone
        self.locale = locale
    }

    private func formatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = locale
        f.timeZone = timeZone
        f.dateFormat = format
        return f
    }

    /// 블록 순서(Q04 잠정): 첫 기록이 맨 아래, 새 기록이 위.
    /// 반환 배열은 위 → 아래 순서(최신 → 과거)이며 화면·VoiceOver 순서와 같다.
    public func blocks(for records: [TimeRecord]) -> [RecordBlock] {
        let time = formatter("HH:mm:ss")
        let date = formatter("M월 d일")
        let spoken = formatter("M월 d일 a h시 m분 s초")
        let day = formatter("d일")
        let monthWeekday = formatter("M월 · E")
        return records.sorted(by: TimeRecord.chronological).reversed().map { r in
            RecordBlock(id: r.id,
                        timeText: time.string(from: r.occurredAt),
                        dateText: date.string(from: r.occurredAt),
                        dayText: day.string(from: r.occurredAt),
                        monthWeekdayText: monthWeekday.string(from: r.occurredAt),
                        accessibilityLabel: spoken.string(from: r.occurredAt) + ", 시간 기록")
        }
    }

    /// "10월 31일 기록" — 기록일은 경계가 시작되는 달력 날짜.
    public func headerTitle(for day: RecordDay) -> String {
        "\(day.month)월 \(day.day)일 기록"
    }

    /// 하루 눈금 양끝 라벨 "10/31 23:00"
    public func edgeText(_ date: Date) -> String {
        formatter("MM/dd HH:mm").string(from: date)
    }

    /// "10/31 23:00 – 11/01 23:00"
    public func rangeText(for interval: RecordDayInterval) -> String {
        let f = formatter("MM/dd HH:mm")
        return "\(f.string(from: interval.start)) – \(f.string(from: interval.end))"
    }

    /// "23:00"
    public static func boundaryText(_ boundary: DayBoundary) -> String {
        String(format: "%02d:%02d", boundary.hour, boundary.minute)
    }

    /// 짧은 확인 표시용 "23:18:42".
    public func timeText(_ date: Date) -> String {
        formatter("HH:mm:ss").string(from: date)
    }
}
