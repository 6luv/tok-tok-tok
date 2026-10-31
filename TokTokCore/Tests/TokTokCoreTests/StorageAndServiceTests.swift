import XCTest
@testable import TokTokCore

/// 임시 디렉터리의 실제 파일 저장소로 검사한다(메모리 저장소 아님).
final class StorageAndServiceTests: XCTestCase {
    var root: URL!
    let seoul = TimeZone(identifier: "Asia/Seoul")!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("toktok-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    func utc(_ iso: String) -> Date { ISO8601DateFormatter().date(from: iso)! }

    final class Counter: @unchecked Sendable {
        private let lock = NSLock()
        private var n = 0
        func next() -> Int { lock.lock(); defer { lock.unlock() }; n += 1; return n }
        var value: Int { lock.lock(); defer { lock.unlock() }; return n }
    }

    func makeService(clock: @escaping RecordTimeService.Clock,
                     repo: RecordRepository? = nil,
                     tz: TimeZone? = nil,
                     configured: Int? = 23 * 60) throws -> RecordTimeService {
        let settings = SettingsStore(fileURL: root.appendingPathComponent("settings.json"))
        if let m = configured { _ = try settings.setDayBoundary(DayBoundary(minutes: m)!) }
        let zone = tz ?? seoul
        return RecordTimeService(repository: repo ?? FileRecordRepository(rootDirectory: root),
                                 settings: settings, clock: clock, timeZone: { zone })
    }

    // MARK: T01 시계 한 번 읽기, 저장 지연이 시각을 바꾸지 않음

    final class SlowRepo: RecordRepository, @unchecked Sendable {
        let inner: RecordRepository
        let onSave: () -> Void
        init(_ inner: RecordRepository, onSave: @escaping () -> Void) { self.inner = inner; self.onSave = onSave }
        func save(_ record: TimeRecord) throws { onSave(); try inner.save(record) }
        func records(from start: Date, to end: Date) throws -> RecordQueryResult { try inner.records(from: start, to: end) }
    }

    func testT01_ClockReadOnceAndUnaffectedBySaveDelay() throws {
        let reads = Counter()
        let base = utc("2026-10-31T14:18:42Z")
        let clock: RecordTimeService.Clock = { base.addingTimeInterval(TimeInterval(reads.next() - 1) * 10) }
        let repo = SlowRepo(FileRecordRepository(rootDirectory: root)) { Thread.sleep(forTimeInterval: 0.05) }
        let service = try makeService(clock: clock, repo: repo)
        let r = try service.recordNow(source: .app)
        XCTAssertEqual(reads.value, 1)
        XCTAssertEqual(r.occurredAt, base)
        XCTAssertEqual(r.recordedTimeZoneID, "Asia/Seoul")
        XCTAssertEqual(r.recordedUTCOffsetSeconds, 9 * 3600)
        XCTAssertEqual(r.source, .app)
    }

    // MARK: T07 경계 변경 후 원본 유지, 표시 그룹 변경

    func testT07_BoundaryChangeKeepsOriginalsAndRegroups() throws {
        let times = ["2026-10-31T13:30:00Z", "2026-10-31T14:30:00Z"] // 서울 22:30, 23:30
        let clockTimes = times.map(utc)
        let counter = Counter()
        let service = try makeService(clock: { clockTimes[counter.next() - 1] })
        var saved: [TimeRecord] = []
        for _ in times { saved.append(try service.recordNow(source: .intent)) }

        // 23:00 경계: 22:30은 10/30, 23:30은 10/31
        let d30 = try service.loadDay(RecordDay(year: 2026, month: 10, day: 30))
        let d31 = try service.loadDay(RecordDay(year: 2026, month: 10, day: 31))
        XCTAssertEqual(d30.records.map(\.id), [saved[0].id])
        XCTAssertEqual(d31.records.map(\.id), [saved[1].id])

        // 00:00로 변경: 둘 다 10/31
        _ = try service.settings.setDayBoundary(DayBoundary(minutes: 0)!)
        let after = try service.loadDay(RecordDay(year: 2026, month: 10, day: 31))
        XCTAssertEqual(after.records, saved) // UUID·원본 시각·건수 동일
        XCTAssertEqual(try service.loadDay(RecordDay(year: 2026, month: 10, day: 30)).records.count, 0)
    }

    // MARK: T09 동시 100개 요청

    func testT09_HundredConcurrentRequestsEachSavedOnce() throws {
        let service = try makeService(clock: { Date() })
        let errors = Counter()
        DispatchQueue.concurrentPerform(iterations: 100) { i in
            do { try service.recordNow(source: i % 2 == 0 ? .app : .intent) } catch { _ = errors.next() }
        }
        XCTAssertEqual(errors.value, 0)
        let all = try FileRecordRepository(rootDirectory: root)
            .records(from: Date().addingTimeInterval(-3600), to: Date().addingTimeInterval(3600))
        XCTAssertEqual(all.records.count, 100)
        XCTAssertEqual(Set(all.records.map(\.id)).count, 100)
        XCTAssertEqual(all.unreadableCount, 0)
    }

    // MARK: T10 다시 열기·원본 필드 동일

    func testT10_ReopenReturnsIdenticalRecords() throws {
        let t = utc("2026-10-31T14:18:42Z").addingTimeInterval(0.123456)
        let service = try makeService(clock: { t })
        let r = try service.recordNow(source: .intent)
        let reopened = FileRecordRepository(rootDirectory: root)
        let got = try reopened.records(from: t.addingTimeInterval(-1), to: t.addingTimeInterval(1))
        XCTAssertEqual(got.records, [r])
        XCTAssertEqual(got.records.first?.occurredAt.timeIntervalSinceReferenceDate, t.timeIntervalSinceReferenceDate)
    }

    func testT10_UnknownSourceValueDecodesAsUnknown() throws {
        let json = #"{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","occurredAt":815148000,"recordedTimeZoneID":"Asia/Seoul","recordedUTCOffsetSeconds":32400,"source":"backTap","schemaVersion":1}"#
        let r = try JSONDecoder().decode(TimeRecord.self, from: Data(json.utf8))
        XCTAssertEqual(r.source, .unknown)
    }

    func testCorruptFileIsCountedNotDeleted() throws {
        let t = utc("2026-10-31T14:00:00Z")
        let service = try makeService(clock: { t })
        try service.recordNow(source: .app)
        let dir = root.appendingPathComponent("records/2026-10")
        let bad = dir.appendingPathComponent("broken.json")
        try Data("{not json".utf8).write(to: bad)
        let got = try FileRecordRepository(rootDirectory: root).records(from: t.addingTimeInterval(-60), to: t.addingTimeInterval(60))
        XCTAssertEqual(got.records.count, 1)
        XCTAssertEqual(got.unreadableCount, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: bad.path))
    }

    // MARK: T11 저장 실패 주입: 성공 응답 없음, 재시도

    func testT11_WriteFailureIsNotReportedAsSuccess() throws {
        // records 자리에 일반 파일을 두어 디렉터리 생성이 실패하게 한다.
        try Data("x".utf8).write(to: root.appendingPathComponent("records"))
        let t = utc("2026-10-31T14:00:00Z")
        let service = try makeService(clock: { t })
        var pending: TimeRecord?
        XCTAssertThrowsError(try service.recordNow(source: .app)) { error in
            guard case RecordError.saveFailed(let p) = error else { return XCTFail("\(error)") }
            pending = p
        }
        XCTAssertEqual(pending?.occurredAt, t)
        // 원인 제거 후 같은 작업으로 재시도 → 원래 시각으로 한 건
        try FileManager.default.removeItem(at: root.appendingPathComponent("records"))
        let saved = try service.retry(pending!)
        XCTAssertEqual(saved, pending)
        XCTAssertEqual(try service.repository.records(from: t.addingTimeInterval(-1), to: t.addingTimeInterval(1)).records, [pending!])
    }

    final class MutableClock: @unchecked Sendable {
        private let lock = NSLock()
        private var v: Date
        init(_ v: Date) { self.v = v }
        var value: Date {
            get { lock.lock(); defer { lock.unlock() }; return v }
            set { lock.lock(); v = newValue; lock.unlock() }
        }
    }

    final class FlakyRepo: RecordRepository, @unchecked Sendable {
        let inner: RecordRepository
        var failuresLeft: Int
        let calls = Counter()
        init(_ inner: RecordRepository, failures: Int) { self.inner = inner; self.failuresLeft = failures }
        func save(_ record: TimeRecord) throws {
            _ = calls.next()
            if failuresLeft > 0 { failuresLeft -= 1; throw StorageError.writeFailed("injected") }
            try inner.save(record)
        }
        func records(from start: Date, to end: Date) throws -> RecordQueryResult { try inner.records(from: start, to: end) }
    }

    func testT11_UserRetryKeepsOriginalTimeAndID() throws {
        let repo = FlakyRepo(FileRecordRepository(rootDirectory: root), failures: 2) // 내부 2회 시도 모두 실패
        let first = utc("2026-10-31T14:00:00Z")
        let now = MutableClock(first)
        let service = try makeService(clock: { now.value }, repo: repo)
        var pending: TimeRecord?
        do { try service.recordNow(source: .app) } catch RecordError.saveFailed(let p) { pending = p }
        XCTAssertNotNil(pending)
        XCTAssertEqual(repo.calls.value, 2)
        XCTAssertEqual(try repo.records(from: first.addingTimeInterval(-1), to: first.addingTimeInterval(1)).records.count, 0)
        now.value = first.addingTimeInterval(120)
        let saved = try service.retry(pending!)
        XCTAssertEqual(saved.occurredAt, first)
        XCTAssertEqual(saved.id, pending!.id)
        XCTAssertEqual(try repo.records(from: first.addingTimeInterval(-1), to: first.addingTimeInterval(1)).records.count, 1)
    }

    func testInternalRetrySucceedsOnSecondAttempt() throws {
        let repo = FlakyRepo(FileRecordRepository(rootDirectory: root), failures: 1)
        let t = utc("2026-10-31T14:00:00Z")
        let service = try makeService(clock: { t }, repo: repo)
        XCTAssertNoThrow(try service.recordNow(source: .intent))
        XCTAssertEqual(try repo.records(from: t.addingTimeInterval(-1), to: t.addingTimeInterval(1)).records.count, 1)
    }

    // MARK: T12 같은 작업 ID는 한 건, 다른 ID 같은 시각은 둘 다

    func testT12_IdempotencyByOperationID() throws {
        let repo = FileRecordRepository(rootDirectory: root)
        let t = utc("2026-10-31T14:00:00Z")
        let a = TimeRecord(id: UUID(), occurredAt: t, timeZone: seoul, source: .intent)
        try repo.save(a)
        try repo.save(a)
        let b = TimeRecord(id: UUID(), occurredAt: t, timeZone: seoul, source: .intent)
        try repo.save(b)
        let got = try repo.records(from: t, to: t.addingTimeInterval(1))
        XCTAssertEqual(got.records.count, 2)
        XCTAssertEqual(Set(got.records.map(\.id)), [a.id, b.id])
    }

    // MARK: T13 설정 저장 실패 시 이전 값 유지

    func testT13_SettingsSaveFailureKeepsPreviousValue() throws {
        let url = root.appendingPathComponent("settings.json")
        let good = SettingsStore(fileURL: url)
        _ = try good.setDayBoundary(DayBoundary(hour: 4, minute: 30)!)
        let failing = SettingsStore(fileURL: url) { _, _ in throw CocoaError(.fileWriteNoPermission) }
        XCTAssertThrowsError(try failing.setDayBoundary(DayBoundary(hour: 9, minute: 0)!))
        XCTAssertEqual(try failing.load().dayStartMinutes, 270)
        XCTAssertEqual(try good.load().dayStartMinutes, 270)
    }

    func testSettingsDefaultIsUnconfigured() throws {
        let s = SettingsStore(fileURL: root.appendingPathComponent("settings.json"))
        XCTAssertNil(try s.load().dayStartMinutes)
        XCTAssertFalse(try s.load().isBoundaryConfigured)
    }

    // MARK: T14 UI 없이 서비스 초기화·기록, 미설정 시 안내 오류

    func testT14_LiveServiceWithoutUIAndUnconfiguredError() throws {
        let service = try RecordTimeService.live(rootDirectory: root.appendingPathComponent("fresh"))
        XCTAssertThrowsError(try service.recordNow(source: .intent)) { error in
            XCTAssertEqual(error as? RecordError, .boundaryNotConfigured)
        }
        // 미설정 오류에서 기록을 몰래 저장하지 않음
        let none = try service.repository.records(from: Date().addingTimeInterval(-60), to: Date().addingTimeInterval(60))
        XCTAssertEqual(none.records.count, 0)
        _ = try service.settings.setDayBoundary(DayBoundary(hour: 13, minute: 37)!)
        let r = try service.recordNow(source: .intent)
        XCTAssertEqual(try service.loadDay().records.map(\.id), [r.id])
    }

    // MARK: T15 같은 시각 여러 기록의 안정된 정렬

    func testT15_StableOrderForEqualTimes() throws {
        let repo = FileRecordRepository(rootDirectory: root)
        let t = utc("2026-10-31T14:00:00Z")
        let recs = (0..<5).map { _ in TimeRecord(id: UUID(), occurredAt: t, timeZone: seoul, source: .app) }
        for r in recs.shuffled() { try repo.save(r) }
        let a = try repo.records(from: t, to: t.addingTimeInterval(1)).records
        let b = try repo.records(from: t, to: t.addingTimeInterval(1)).records
        XCTAssertEqual(a, b)
        XCTAssertEqual(a, recs.sorted(by: TimeRecord.chronological))
    }

    // MARK: 월 경계를 걸치는 조회

    func testQuerySpansMonthDirectories() throws {
        let repo = FileRecordRepository(rootDirectory: root)
        let a = TimeRecord(id: UUID(), occurredAt: utc("2026-10-31T23:59:00Z"), timeZone: seoul, source: .app)
        let b = TimeRecord(id: UUID(), occurredAt: utc("2026-11-01T00:01:00Z"), timeZone: seoul, source: .app)
        try repo.save(a); try repo.save(b)
        let got = try repo.records(from: utc("2026-10-31T12:00:00Z"), to: utc("2026-11-01T12:00:00Z"))
        XCTAssertEqual(got.records, [a, b])
        XCTAssertEqual(FileRecordRepository.monthKeys(from: utc("2026-12-31T00:00:00Z"), to: utc("2027-01-01T00:00:00Z")), ["2026-12"])
    }
}
