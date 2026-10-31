import XCTest
@testable import TokTokCore

/// TEST_PLAN T02~T06, T08. 00:00·06:00·23:00·13:37은 입력 예시이며 제품 기본값이 아니다.
final class DayBoundaryCalculatorTests: XCTestCase {
    let seoul = TimeZone(identifier: "Asia/Seoul")!
    let newYork = TimeZone(identifier: "America/New_York")!
    let losAngeles = TimeZone(identifier: "America/Los_Angeles")!

    /// 지정 시간대의 지역 시각을 절대 시각으로 만든다(테스트 입력용; 존재하는 시각만 사용).
    func date(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int, _ s: Int = 0, tz: TimeZone) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        return cal.date(from: DateComponents(year: y, month: mo, day: d, hour: h, minute: mi, second: s))!
    }

    func calc(_ h: Int, _ m: Int, _ tz: TimeZone) -> DayBoundaryCalculator {
        DayBoundaryCalculator(boundary: DayBoundary(hour: h, minute: m)!, timeZone: tz)
    }

    func utc(_ iso: String) -> Date {
        let f = ISO8601DateFormatter()
        return f.date(from: iso)!
    }

    // MARK: DayBoundary 값 범위

    func testBoundaryRange() {
        XCTAssertNotNil(DayBoundary(minutes: 0))
        XCTAssertNotNil(DayBoundary(minutes: 1439))
        XCTAssertNil(DayBoundary(minutes: -1))
        XCTAssertNil(DayBoundary(minutes: 1440))
        XCTAssertNil(DayBoundary(hour: 24, minute: 0))
        XCTAssertNil(DayBoundary(hour: 10, minute: 60))
        XCTAssertEqual(DayBoundary(hour: 13, minute: 37)?.minutes, 817)
    }

    // MARK: T02 직전·정확히·직후

    func testT02_BeforeAtAfterForSeveralBoundaries() {
        for (h, m) in [(0, 0), (6, 0), (23, 0), (13, 37)] {
            let c = calc(h, m, seoul)
            let at = date(2026, 10, 31, h, m, tz: seoul)
            let before = at.addingTimeInterval(-1)
            let after = at.addingTimeInterval(1)
            XCTAssertEqual(c.recordDay(containing: at), RecordDay(year: 2026, month: 10, day: 31), "\(h):\(m) 정확히")
            XCTAssertEqual(c.recordDay(containing: after), RecordDay(year: 2026, month: 10, day: 31), "\(h):\(m) 직후")
            XCTAssertEqual(c.recordDay(containing: before), RecordDay(year: 2026, month: 10, day: 30), "\(h):\(m) 직전")
        }
    }

    // MARK: T03 PRD 예시

    func testT03_PRDExample23() {
        let c = calc(23, 0, seoul)
        XCTAssertEqual(c.recordDay(containing: date(2026, 10, 31, 22, 59, 59, tz: seoul)), RecordDay(year: 2026, month: 10, day: 30))
        XCTAssertEqual(c.recordDay(containing: date(2026, 10, 31, 23, 0, 0, tz: seoul)), RecordDay(year: 2026, month: 10, day: 31))
        // 10/31 기록일 안의 11/01 03:15 기록: 블록 날짜는 11/01
        let lateNight = date(2026, 11, 1, 3, 15, 8, tz: seoul)
        XCTAssertEqual(c.recordDay(containing: lateNight), RecordDay(year: 2026, month: 10, day: 31))
        XCTAssertEqual(c.calendarDay(of: lateNight), RecordDay(year: 2026, month: 11, day: 1))
    }

    func testMidnightBoundaryMatchesCalendarDate() {
        let c = calc(0, 0, seoul)
        let d = date(2026, 3, 5, 12, 0, tz: seoul)
        XCTAssertEqual(c.recordDay(containing: d), c.calendarDay(of: d))
    }

    // MARK: T04 월말·연말·윤년, 임의 분 값

    func testT04_MonthYearLeapEdges() {
        let c = calc(4, 30, seoul)
        XCTAssertEqual(c.recordDay(containing: date(2026, 11, 1, 4, 29, 59, tz: seoul)), RecordDay(year: 2026, month: 10, day: 31))
        XCTAssertEqual(c.recordDay(containing: date(2027, 1, 1, 4, 29, tz: seoul)), RecordDay(year: 2026, month: 12, day: 31))
        XCTAssertEqual(c.recordDay(containing: date(2028, 3, 1, 4, 0, tz: seoul)), RecordDay(year: 2028, month: 2, day: 29))
        XCTAssertEqual(c.recordDay(containing: date(2027, 3, 1, 4, 0, tz: seoul)), RecordDay(year: 2027, month: 2, day: 28))
        XCTAssertEqual(RecordDay(year: 2028, month: 2, day: 28).next, RecordDay(year: 2028, month: 2, day: 29))
        XCTAssertEqual(RecordDay(year: 2026, month: 12, day: 31).next, RecordDay(year: 2027, month: 1, day: 1))
        XCTAssertEqual(RecordDay(year: 2100, month: 2, day: 28).next, RecordDay(year: 2100, month: 3, day: 1))
    }

    func testT04_EveryBoundaryMinuteRoundTrips() {
        let days = [RecordDay(year: 2026, month: 12, day: 31), RecordDay(year: 2028, month: 2, day: 29)]
        for tz in [seoul, newYork] {
            for minutes in 0..<1440 {
                let c = DayBoundaryCalculator(boundary: DayBoundary(minutes: minutes)!, timeZone: tz)
                for day in days {
                    let iv = c.interval(for: day)
                    XCTAssertLessThan(iv.start, iv.end)
                    XCTAssertEqual(c.recordDay(containing: iv.start), day, "\(tz.identifier) \(minutes) start")
                    XCTAssertEqual(c.recordDay(containing: iv.end.addingTimeInterval(-1)), day, "\(tz.identifier) \(minutes) end-1")
                    XCTAssertEqual(c.recordDay(containing: iv.end), day.next, "\(tz.identifier) \(minutes) end")
                }
            }
        }
    }

    // MARK: T05 DST: 존재하지 않는 시각 / 두 번 나타나는 시각

    func testT05_SpringForwardGapUsesFirstValidInstant() {
        // 2026-03-08 02:00 EST → 03:00 EDT. 02:30은 존재하지 않음 → 전환 순간(03:00 EDT = 07:00Z).
        let c = calc(2, 30, newYork)
        let start = c.start(of: RecordDay(year: 2026, month: 3, day: 8))
        XCTAssertEqual(start, utc("2026-03-08T07:00:00Z"))
        XCTAssertEqual(c.recordDay(containing: utc("2026-03-08T06:59:59Z")), RecordDay(year: 2026, month: 3, day: 7))
        XCTAssertEqual(c.recordDay(containing: utc("2026-03-08T07:00:00Z")), RecordDay(year: 2026, month: 3, day: 8))
    }

    func testT05_FallBackRepeatUsesFirstOccurrence() {
        // 2026-11-01 02:00 EDT → 01:00 EST. 01:30은 두 번: 05:30Z(EDT), 06:30Z(EST). 첫 번째 사용.
        let c = calc(1, 30, newYork)
        let start = c.start(of: RecordDay(year: 2026, month: 11, day: 1))
        XCTAssertEqual(start, utc("2026-11-01T05:30:00Z"))
        // 두 번째 01:30(EST)도 11/01 기록일(경계는 첫 번째에서 이미 지남)
        XCTAssertEqual(c.recordDay(containing: utc("2026-11-01T06:30:00Z")), RecordDay(year: 2026, month: 11, day: 1))
        XCTAssertEqual(c.recordDay(containing: utc("2026-11-01T05:29:59Z")), RecordDay(year: 2026, month: 10, day: 31))
    }

    // MARK: T06 DST 양쪽 구간 누락·중복 없음, 고정 24시간 가정 없음

    func testT06_ContiguousIntervalsAcrossDST() {
        for (h, m) in [(0, 0), (1, 30), (2, 30), (13, 37), (23, 0)] {
            let c = calc(h, m, newYork)
            var day = RecordDay(year: 2026, month: 3, day: 5)
            while day < RecordDay(year: 2026, month: 3, day: 12) {
                XCTAssertEqual(c.interval(for: day).end, c.interval(for: day.next).start)
                day = day.next
            }
            day = RecordDay(year: 2026, month: 10, day: 29)
            while day < RecordDay(year: 2026, month: 11, day: 5) {
                XCTAssertEqual(c.interval(for: day).end, c.interval(for: day.next).start)
                day = day.next
            }
        }
        // 13:37 경계: 3/7 기록일은 23시간, 10/31 기록일은 25시간
        let c = calc(13, 37, newYork)
        XCTAssertEqual(c.interval(for: RecordDay(year: 2026, month: 3, day: 7)).duration, 23 * 3600)
        XCTAssertEqual(c.interval(for: RecordDay(year: 2026, month: 10, day: 31)).duration, 25 * 3600)
        XCTAssertEqual(c.interval(for: RecordDay(year: 2026, month: 6, day: 1)).duration, 24 * 3600)
    }

    func testT06_EveryHourAcrossDSTWeekMapsToExactlyOneContainingInterval() {
        let c = calc(2, 30, newYork)
        var t = utc("2026-03-06T00:00:00Z")
        let endT = utc("2026-03-11T00:00:00Z")
        while t < endT {
            let d = c.recordDay(containing: t)
            XCTAssertTrue(c.interval(for: d).contains(t), "\(t)")
            XCTAssertFalse(c.interval(for: d.previous).contains(t))
            XCTAssertFalse(c.interval(for: d.next).contains(t))
            t = t.addingTimeInterval(900)
        }
    }

    // MARK: T08 시간대 변경 시 조회 정책(현재 기기 시간대 기준, 잠정 Q03)

    func testT08_SameInstantGroupsByViewingTimeZone() {
        let instant = utc("2026-10-31T14:30:00Z") // 서울 10/31 23:30, LA 10/31 07:30
        XCTAssertEqual(calc(23, 0, seoul).recordDay(containing: instant), RecordDay(year: 2026, month: 10, day: 31))
        XCTAssertEqual(calc(23, 0, losAngeles).recordDay(containing: instant), RecordDay(year: 2026, month: 10, day: 30))
    }

    // MARK: Civil 날짜 연산

    func testCivilRoundTrip() {
        for n in stride(from: -800_000, through: 800_000, by: 997) {
            XCTAssertEqual(RecordDay(dayNumber: n).dayNumber, n)
        }
        XCTAssertEqual(RecordDay(year: 1970, month: 1, day: 1).dayNumber, 0)
    }

    // MARK: S05 Calendar.nextDate 정책과 교차 확인

    func testMatchesFoundationNextDatePolicy() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = newYork
        let days = [RecordDay(year: 2026, month: 3, day: 8), RecordDay(year: 2026, month: 11, day: 1), RecordDay(year: 2026, month: 7, day: 4)]
        for minutes in stride(from: 0, to: 1440, by: 15) {
            let c = DayBoundaryCalculator(boundary: DayBoundary(minutes: minutes)!, timeZone: newYork)
            for day in days {
                let dayStart = cal.startOfDay(for: cal.date(from: DateComponents(year: day.year, month: day.month, day: day.day, hour: 12))!)
                let expected = cal.nextDate(after: dayStart.addingTimeInterval(-1),
                                            matching: DateComponents(hour: minutes / 60, minute: minutes % 60),
                                            matchingPolicy: .nextTime,
                                            repeatedTimePolicy: .first,
                                            direction: .forward)
                XCTAssertEqual(c.start(of: day), expected, "\(day) \(minutes)")
            }
        }
    }
}
