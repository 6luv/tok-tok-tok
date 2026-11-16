import Foundation

/// 사용자 설정. 문자열 시간이 아니라 분 단위 정수를 원본으로 저장한다.
public struct AppSettings: Codable, Equatable, Sendable {
    public static let currentVersion = 1

    public var version: Int
    /// 하루 시작(0~1439분). nil이면 아직 설정하지 않음(Q01 잠정: 첫 실행에서 선택·확인 필요).
    public var dayStartMinutes: Int?

    public init(dayStartMinutes: Int? = nil) {
        self.version = AppSettings.currentVersion
        self.dayStartMinutes = dayStartMinutes
    }

    public var isBoundaryConfigured: Bool { boundary != nil }
    public var boundary: DayBoundary? { dayStartMinutes.flatMap(DayBoundary.init(minutes:)) }
}

public enum SettingsError: Error, Equatable, Sendable {
    case saveFailed(String)
    case loadFailed(String)
}

/// 경계 설정 저장소. 원자적 쓰기로 실패 시 이전 값을 유지한다(T13).
public final class SettingsStore: @unchecked Sendable {
    public typealias Writer = @Sendable (Data, URL) throws -> Void

    public let fileURL: URL
    private let writer: Writer
    private let lock = NSLock()

    public static let defaultWriter: Writer = { data, url in
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: FileRecordRepository.writeOptions)
    }

    public init(fileURL: URL, writer: @escaping Writer = SettingsStore.defaultWriter) {
        self.fileURL = fileURL
        self.writer = writer
    }

    /// 일관된 설정 스냅샷. 파일이 없으면 미설정 상태.
    public func load() throws -> AppSettings {
        lock.lock(); defer { lock.unlock() }
        return try loadLocked()
    }

    private func loadLocked() throws -> AppSettings {
        // 다른 실행 경로가 바꿨을 수 있으므로 매번 파일을 읽는다.
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return AppSettings()
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let s = try JSONDecoder().decode(AppSettings.self, from: data)
            return s
        } catch {
            throw SettingsError.loadFailed(String(describing: error))
        }
    }

    /// 저장 실패 시 이전 값이 그대로 유지된다(원자적 쓰기).
    public func setDayBoundary(_ boundary: DayBoundary) throws -> AppSettings {
        lock.lock(); defer { lock.unlock() }
        var next = (try? loadLocked()) ?? AppSettings()
        next.dayStartMinutes = boundary.minutes
        next.version = AppSettings.currentVersion
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            try writer(try encoder.encode(next), fileURL)
        } catch {
            throw SettingsError.saveFailed(String(describing: error))
        }
        return next
    }
}
