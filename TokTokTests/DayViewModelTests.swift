import XCTest
import TokTokCore
@testable import TokTok

/// 앱 타깃 단위 테스트(실기기에서 실행). 임시 디렉터리의 실제 파일 저장소를 사용한다.
@MainActor
final class DayViewModelTests: XCTestCase {
    var root: URL!

    override func setUp() async throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("toktok-vm-\(UUID().uuidString)")
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: root)
    }

    func makeModel() -> DayViewModel {
        let r = root!
        return DayViewModel(serviceFactory: { try RecordTimeService.live(rootDirectory: r) })
    }

    func testUnconfiguredShowsSetup() async {
        let model = makeModel()
        await model.reload()
        XCTAssertEqual(model.state, .needsSetup)
    }

    func testSetupThenRecordAddsNewestBlockOnTop() async throws {
        let model = makeModel()
        try await model.saveBoundary(DayBoundary(minutes: 0)!)
        XCTAssertEqual(model.state, .loaded)
        XCTAssertTrue(model.blocks.isEmpty)

        model.recordTapped()
        try await waitUntil { model.inFlight == 0 && model.blocks.count == 1 }
        model.recordTapped()
        try await waitUntil { model.inFlight == 0 && model.blocks.count == 2 }
        // 위 → 아래 = 최신 → 과거
        let times = model.blocks.map(\.timeText)
        XCTAssertGreaterThanOrEqual(times[0], times[1])
        XCTAssertTrue(model.blocks.contains { $0.id == model.scrollTarget })
    }

    /// 스와이프 삭제(Q06 2026-11-11): 고른 기록 하나만 지우고 나머지는 남는다.
    func testDeleteOneRemovesOnlyThatRecord() async throws {
        let model = makeModel()
        try await model.saveBoundary(DayBoundary(minutes: 0)!)
        let first = try model.service!.recordNow(source: .app)
        let second = try model.service!.recordNow(source: .app)
        await model.reload()
        XCTAssertEqual(model.blocks.count, 2)

        await model.deleteOne(first.id)
        try await waitUntil { model.blocks.count == 1 }
        XCTAssertEqual(model.blocks.map(\.id), [second.id])
        XCTAssertNil(model.feedback)
    }

    /// 대상이 이미 목록에 없으면 아무것도 지우지 않고 알린다(Codex 검증 P2).
    func testDeleteOneMissingTargetDeletesNothingAndReports() async throws {
        let model = makeModel()
        try await model.saveBoundary(DayBoundary(minutes: 0)!)
        _ = try model.service!.recordNow(source: .app)
        await model.reload()
        await model.deleteOne(UUID())
        XCTAssertEqual(model.blocks.count, 1)
        if case .error = model.feedback {} else { XCTFail("오류 알림이 있어야 함") }
    }

    func testExternalRecordWhileScrolledAwayCountsUnseen() async throws {
        let model = makeModel()
        try await model.saveBoundary(DayBoundary(minutes: 0)!)
        model.isViewingNewest = false
        try model.service!.recordNow(source: .intent) // 외부 Intent 기록 흉내
        await model.reload(markExternal: true)
        XCTAssertEqual(model.unseenCount, 1)
        model.showNewest()
        XCTAssertEqual(model.unseenCount, 0)
    }

    func testBoundaryExampleText() {
        let seoul = TimeZone(identifier: "Asia/Seoul")!
        let now = ISO8601DateFormatter().date(from: "2026-10-31T14:30:00Z")! // 서울 23:30
        let text = BoundaryExample.text(for: DayBoundary(hour: 23, minute: 0)!, now: now, timeZone: seoul)
        XCTAssertTrue(text.contains("10/31 23:00 – 11/01 23:00"), text)
    }

    private func waitUntil(timeout: TimeInterval = 5, _ condition: @MainActor () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            if Date() > deadline { XCTFail("timeout"); return }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
    }
}
