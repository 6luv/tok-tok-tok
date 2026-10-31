import Foundation

/// 사용자가 지정한 하루 시작 시각(로컬 시·분). 0...1439분.
///
/// 제품 기본값은 없다(QUESTIONS Q01 미결정). 06:00·23:00을 기본값으로 쓰지 않는다.
public struct DayBoundary: Hashable, Codable, Sendable {
    public let minutes: Int

    public init?(minutes: Int) {
        guard (0...1439).contains(minutes) else { return nil }
        self.minutes = minutes
    }

    public init?(hour: Int, minute: Int) {
        guard (0...23).contains(hour), (0...59).contains(minute) else { return nil }
        self.init(minutes: hour * 60 + minute)
    }

    public var hour: Int { minutes / 60 }
    public var minute: Int { minutes % 60 }
}

/// 기록일. 하루 경계가 시작되는 달력 날짜(그레고리력)로 식별한다.
public struct RecordDay: Hashable, Comparable, Codable, Sendable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// 1970-01-01부터의 일 수(그레고리력 달력 연산, 초 단위 덧셈 아님).
    var dayNumber: Int { CivilDate.daysFromCivil(year: year, month: month, day: day) }

    init(dayNumber: Int) {
        let c = CivilDate.civilFromDays(dayNumber)
        self.init(year: c.year, month: c.month, day: c.day)
    }

    public func adding(days: Int) -> RecordDay { RecordDay(dayNumber: dayNumber + days) }
    public var next: RecordDay { adding(days: 1) }
    public var previous: RecordDay { adding(days: -1) }

    public static func < (lhs: RecordDay, rhs: RecordDay) -> Bool { lhs.dayNumber < rhs.dayNumber }

    public var description: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }
}

/// 기록일 구간 [start, end).
public struct RecordDayInterval: Hashable, Sendable {
    public let day: RecordDay
    public let start: Date
    public let end: Date

    public func contains(_ date: Date) -> Bool { date >= start && date < end }
    public var duration: TimeInterval { end.timeIntervalSince(start) }
}

/// 사용자 지정 경계로 기록일을 계산하는 독립 계산기.
///
/// 정책(PRD §5, 잠정):
/// - 구간은 [해당 날짜의 경계, 다음 날짜의 경계). 경계와 같은 순간은 새 기록일.
/// - 경계 지역 시각이 DST로 존재하지 않으면 그 이후 첫 유효 시각(전환 순간)을 사용.
/// - 경계 지역 시각이 두 번 나타나면 첫 번째 발생을 사용.
/// - 하루를 86,400초로 가정하지 않는다. 날짜 이동은 달력 날짜 연산으로만 한다.
public struct DayBoundaryCalculator: Sendable {
    public let timeZone: TimeZone
    public let boundary: DayBoundary

    public init(boundary: DayBoundary, timeZone: TimeZone) {
        self.boundary = boundary
        self.timeZone = timeZone
    }

    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = timeZone
        return c
    }

    /// 해당 기록일의 시작 순간.
    public func start(of day: RecordDay) -> Date {
        instant(forWallClock: day, minutes: boundary.minutes)
    }

    public func interval(for day: RecordDay) -> RecordDayInterval {
        RecordDayInterval(day: day, start: start(of: day), end: start(of: day.next))
    }

    /// 주어진 순간이 속한 기록일.
    public func recordDay(containing date: Date) -> RecordDay {
        let local = calendarDay(of: date)
        // 해당 달력 날짜의 경계 이후면 그 날짜, 이전이면 전날 기록일.
        if date >= start(of: local) { return local }
        return local.previous
    }

    /// 순간의 (현재 시간대 기준) 실제 달력 날짜. 블록의 작은 날짜 표시에 사용.
    public func calendarDay(of date: Date) -> RecordDay {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return RecordDay(year: c.year!, month: c.month!, day: c.day!)
    }

    // MARK: - 지역 시각 → 절대 시각 (DST 정책 포함)

    /// 지역 벽시계 시각(날짜 + 분)을 이 시간대의 절대 시각으로 변환한다.
    /// TimeZone.secondsFromGMT(for:)만 사용해 플랫폼 간 동작을 일치시킨다.
    func instant(forWallClock day: RecordDay, minutes: Int) -> Date {
        // 시간대 오프셋이 0일 때의 epoch 초(벽시계 값).
        let wall = Int64(day.dayNumber) * 86_400 + Int64(minutes) * 60
        let tz = timeZone

        func offset(at t: Int64) -> Int64 {
            Int64(tz.secondsFromGMT(for: Date(timeIntervalSince1970: TimeInterval(t))))
        }

        // 주변에 나타날 수 있는 오프셋 후보 수집(앞뒤 48시간, 1시간 간격).
        var offsets = Set<Int64>()
        var k: Int64 = -48
        while k <= 48 {
            offsets.insert(offset(at: wall + k * 3600))
            k += 1
        }

        // 해당 벽시계 시각에 실제로 대응하는 순간들(반복 시각이면 2개).
        let valid = offsets.map { wall - $0 }.filter { offset(at: $0) == wall - $0 }
        if let first = valid.min() {
            return Date(timeIntervalSince1970: TimeInterval(first))
        }

        // 존재하지 않는 시각(DST 앞당김 구간): 전환 순간을 찾는다.
        // 전환 직전 오프셋 offB, 직후 offA(> offB)라면 전환 T는 (wall - offA, wall - offB] 안에 있다.
        let sorted = offsets.sorted()
        var lo = wall - sorted.last!   // 전환 이전 쪽 순간
        var hi = wall - sorted.first!  // 전환 이후 쪽 순간
        let offLo = offset(at: lo)
        // offset(lo) != offset(hi)인 가장 이른 hi를 이진 탐색.
        while hi - lo > 1 {
            let mid = lo + (hi - lo) / 2
            if offset(at: mid) == offLo { lo = mid } else { hi = mid }
        }
        return Date(timeIntervalSince1970: TimeInterval(hi))
    }
}

/// 그레고리력 날짜 ↔ 일 수 변환 (Howard Hinnant의 civil 알고리즘).
enum CivilDate {
    static func daysFromCivil(year: Int, month: Int, day: Int) -> Int {
        let y = month <= 2 ? year - 1 : year
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let mp = (month + 9) % 12
        let doy = (153 * mp + 2) / 5 + day - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146_097 + doe - 719_468
    }

    static func civilFromDays(_ z0: Int) -> (year: Int, month: Int, day: Int) {
        let z = z0 + 719_468
        let era = (z >= 0 ? z : z - 146_096) / 146_097
        let doe = z - era * 146_097
        let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365
        let y = yoe + era * 400
        let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
        let mp = (5 * doy + 2) / 153
        let d = doy - (153 * mp + 2) / 5 + 1
        let m = mp < 10 ? mp + 3 : mp - 9
        return (m <= 2 ? y + 1 : y, m, d)
    }
}
