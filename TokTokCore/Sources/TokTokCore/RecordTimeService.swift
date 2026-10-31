import Foundation

public enum RecordError: Error, Equatable, Sendable {
    /// 하루 경계를 아직 설정하지 않음(Q01 잠정). 앱에서 초기 설정을 마쳐야 한다.
    case boundaryNotConfigured
    /// 저장 실패. 실패한 기록(원래 시각·작업 ID)을 담아 같은 ID로 재시도할 수 있게 한다.
    case saveFailed(pending: TimeRecord)
    /// 설정을 읽지 못함.
    case settingsUnavailable
}

/// 하루 화면에 필요한 조회 결과.
public struct DaySnapshot: Sendable, Equatable {
    public let interval: RecordDayInterval
    /// 시간순(과거 → 최신). 화면 쌓기 순서는 UI가 결정한다.
    public let records: [TimeRecord]
    public let unreadableCount: Int
    public let boundary: DayBoundary
    public let timeZone: TimeZone
}

/// UI와 App Intent의 공용 진입점. 화면(Scene) 없이도 생성·사용할 수 있다.
public final class RecordTimeService: @unchecked Sendable {
    public typealias Clock = @Sendable () -> Date
    public typealias TimeZoneProvider = @Sendable () -> TimeZone
    public typealias IDGenerator = @Sendable () -> UUID

    public let repository: RecordRepository
    public let settings: SettingsStore
    private let clock: Clock
    private let timeZoneProvider: TimeZoneProvider
    private let makeID: IDGenerator
    private let maxAttempts: Int

    public init(repository: RecordRepository,
                settings: SettingsStore,
                clock: @escaping Clock = { Date() },
                timeZone: @escaping TimeZoneProvider = { TimeZone.current },
                idGenerator: @escaping IDGenerator = { UUID() },
                maxAttempts: Int = 2) {
        self.repository = repository
        self.settings = settings
        self.clock = clock
        self.timeZoneProvider = timeZone
        self.makeID = idGenerator
        self.maxAttempts = max(1, maxAttempts)
    }

    /// 앱 기본 위치(Application Support/TokTok)를 사용하는 실제 서비스.
    public static func live(rootDirectory: URL? = nil) throws -> RecordTimeService {
        let root = try rootDirectory ?? StorageLocation.defaultRoot()
        return RecordTimeService(
            repository: FileRecordRepository(rootDirectory: root),
            settings: SettingsStore(fileURL: root.appendingPathComponent("settings.json"))
        )
    }

    /// 현재 시각 기록. 시계는 진입 시 한 번만 읽는다(T01).
    /// 저장이 확인된 뒤에만 기록을 반환한다. 실패를 성공으로 알리지 않는다(R08).
    @discardableResult
    public func recordNow(source: RecordSource) throws -> TimeRecord {
        let now = clock()
        let tz = timeZoneProvider()
        let current: AppSettings
        do { current = try settings.load() } catch { throw RecordError.settingsUnavailable }
        guard current.isBoundaryConfigured else { throw RecordError.boundaryNotConfigured }
        let record = TimeRecord(id: makeID(), occurredAt: now, timeZone: tz, source: source)
        return try persist(record)
    }

    /// 같은 작업 ID·원래 시각으로 저장을 다시 시도한다(멱등). 새 시각을 만들지 않는다.
    @discardableResult
    public func retry(_ pending: TimeRecord) throws -> TimeRecord {
        try persist(pending)
    }

    private func persist(_ record: TimeRecord) throws -> TimeRecord {
        var attempt = 0
        while true {
            attempt += 1
            do {
                try repository.save(record)
                return record
            } catch {
                if attempt >= maxAttempts { throw RecordError.saveFailed(pending: record) }
            }
        }
    }

    /// 최근 lookback 기간 안에서 해당 경로로 저장된 가장 최근 기록.
    /// 뒷면 탭·단축어 연결 확인용이며, 어느 트리거였는지는 구분하지 않는다(모두 `.intent`).
    public func latestRecord(source: RecordSource, lookback: TimeInterval = 14 * 86_400) throws -> TimeRecord? {
        let now = clock()
        let result = try repository.records(from: now.addingTimeInterval(-lookback), to: now.addingTimeInterval(60))
        return result.records.last { $0.source == source }
    }

    /// 현재 시각이 속한 기록일. 미설정이면 nil.
    public func currentRecordDay() throws -> RecordDay? {
        let s: AppSettings
        do { s = try settings.load() } catch { throw RecordError.settingsUnavailable }
        guard let boundary = s.boundary else { return nil }
        return DayBoundaryCalculator(boundary: boundary, timeZone: timeZoneProvider()).recordDay(containing: clock())
    }

    /// 한 기록일 조회. 설정 스냅샷 하나와 현재 기기 시간대(Q03 잠정)로 계산한다.
    /// day가 nil이면 현재 기록일.
    public func loadDay(_ day: RecordDay? = nil) throws -> DaySnapshot {
        let s: AppSettings
        do { s = try settings.load() } catch { throw RecordError.settingsUnavailable }
        guard let boundary = s.boundary else { throw RecordError.boundaryNotConfigured }
        let tz = timeZoneProvider()
        let calc = DayBoundaryCalculator(boundary: boundary, timeZone: tz)
        let target = day ?? calc.recordDay(containing: clock())
        let interval = calc.interval(for: target)
        let result = try repository.records(from: interval.start, to: interval.end)
        return DaySnapshot(interval: interval, records: result.records,
                           unreadableCount: result.unreadableCount, boundary: boundary, timeZone: tz)
    }
}

public enum StorageLocation {
    /// 앱 컨테이너의 Application Support/TokTok. App Group은 사용하지 않는다
    /// (App Intent를 앱 타깃에 두어 같은 컨테이너를 쓰기 때문).
    public static func defaultRoot() throws -> URL {
        let base = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                               appropriateFor: nil, create: true)
        return base.appendingPathComponent("TokTok", isDirectory: true)
    }
}
