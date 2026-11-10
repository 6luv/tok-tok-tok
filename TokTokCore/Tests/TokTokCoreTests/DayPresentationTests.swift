import XCTest
@testable import TokTokCore

/// DESIGN.md 표시 규칙과 T15(블록 날짜와 헤더 구분).
final class DayPresentationTests: XCTestCase {
    let seoul = TimeZone(identifier: "Asia/Seoul")!

    func utc(_ iso: String) -> Date { ISO8601DateFormatter().date(from: iso)! }

    func testDesignExample() {
        let calc = DayBoundaryCalculator(boundary: DayBoundary(hour: 23, minute: 0)!, timeZone: seoul)
        let p = DayPresentation(timeZone: seoul)
        let first = TimeRecord(id: UUID(), occurredAt: utc("2026-10-31T14:18:42Z"), timeZone: seoul, source: .app)   // 10/31 23:18:42
        let second = TimeRecord(id: UUID(), occurredAt: utc("2026-10-31T18:15:08Z"), timeZone: seoul, source: .intent) // 11/01 03:15:08
        let day = calc.recordDay(containing: first.occurredAt)
        XCTAssertEqual(p.headerTitle(for: day), "10월 31일 기록")
        XCTAssertEqual(p.rangeText(for: calc.interval(for: day)), "10/31 23:00 – 11/01 23:00")

        let blocks = p.blocks(for: [first, second])
        // 위 → 아래: 새 기록(11/01 03:15:08)이 위, 첫 기록이 맨 아래
        XCTAssertEqual(blocks.map(\.id), [second.id, first.id])
        XCTAssertEqual(blocks[0].timeText, "03:15:08")
        XCTAssertEqual(blocks[0].dateText, "11월 1일")
        XCTAssertEqual(blocks[0].dayText, "1일")
        XCTAssertEqual(blocks[0].monthWeekdayText, "11월 · 일")
        XCTAssertEqual(blocks[1].timeText, "23:18:42")
        XCTAssertEqual(blocks[1].dateText, "10월 31일")
        XCTAssertEqual(blocks[0].accessibilityLabel, "11월 1일 오전 3시 15분 8초, 시간 기록")
        XCTAssertEqual(blocks[1].accessibilityLabel, "10월 31일 오후 11시 18분 42초, 시간 기록")
    }

    func testBlocksOrderIndependentOfInputOrder() {
        let p = DayPresentation(timeZone: seoul)
        let t = utc("2026-10-31T14:00:00Z")
        let recs = (0..<4).map { i in TimeRecord(id: UUID(), occurredAt: t.addingTimeInterval(Double(i % 2)), timeZone: seoul, source: .app) }
        XCTAssertEqual(p.blocks(for: recs).map(\.id), p.blocks(for: recs.shuffled()).map(\.id))
    }

    func testBoundaryText() {
        XCTAssertEqual(DayPresentation.boundaryText(DayBoundary(hour: 4, minute: 5)!), "04:05")
        XCTAssertEqual(DayPresentation.boundaryText(DayBoundary(minutes: 0)!), "00:00")
    }
}
