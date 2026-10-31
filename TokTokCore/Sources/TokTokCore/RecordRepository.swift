import Foundation

public enum StorageError: Error, Equatable, Sendable {
    /// 쓰기 실패. 성공으로 알리지 않는다.
    case writeFailed(String)
    /// 기록 후 다시 읽어 확인하지 못함.
    case verificationFailed
    /// 조회 실패. 기록이 삭제됐다는 뜻이 아니다.
    case readFailed(String)
}

/// 조회 결과. 읽지 못한 파일은 삭제하지 않고 개수만 알린다.
public struct RecordQueryResult: Sendable, Equatable {
    public let records: [TimeRecord]
    public let unreadableCount: Int
}

public protocol RecordRepository: Sendable {
    /// 저장 완료 후 반환. 같은 ID가 이미 있으면 새로 만들지 않는다(멱등).
    func save(_ record: TimeRecord) throws
    /// [start, end) 구간의 기록을 시간순으로 반환.
    func records(from start: Date, to end: Date) throws -> RecordQueryResult
}

/// 기록 1건 = 파일 1개인 로컬 저장소.
///
/// - 레이아웃: `<root>/records/<UTC yyyy-MM>/<UUID>.json`
/// - 각 파일은 원자적 쓰기(임시 파일 → rename)로 만든다. 공유 파일을 고치지 않으므로
///   같은 프로세스의 동시 요청이나 별도 프로세스의 쓰기가 서로의 기록을 덮어쓰지 않는다.
/// - iOS 파일 보호: `completeUntilFirstUserAuthentication`(iOS 기본값과 같은 수준).
///   재부팅 후 최초 잠금 해제 전에는 쓰기가 실패할 수 있으며 실기기 확인 대상이다.
/// - 서버·CloudKit 동기화 없음. OS 기기 백업 포함 여부는 별개다.
public final class FileRecordRepository: RecordRepository, @unchecked Sendable {
    public let rootDirectory: URL
    private let fileManager = FileManager.default
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        e.dateEncodingStrategy = .deferredToDate // Double 원본 그대로 왕복
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .deferredToDate
        return d
    }()

    public init(rootDirectory: URL) {
        self.rootDirectory = rootDirectory
    }

    var recordsDirectory: URL { rootDirectory.appendingPathComponent("records", isDirectory: true) }

    static func monthKey(for date: Date) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let c = cal.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", c.year!, c.month!)
    }

    func fileURL(for record: TimeRecord) -> URL {
        recordsDirectory
            .appendingPathComponent(Self.monthKey(for: record.occurredAt), isDirectory: true)
            .appendingPathComponent(record.id.uuidString + ".json")
    }

    public func save(_ record: TimeRecord) throws {
        let url = fileURL(for: record)
        if fileManager.fileExists(atPath: url.path) {
            // 같은 작업 ID 재시도: 기존 파일이 같은 기록이면 성공으로 본다.
            if let existing = try? decoder.decode(TimeRecord.self, from: Data(contentsOf: url)), existing == record {
                return
            }
            throw StorageError.writeFailed("다른 내용의 같은 ID 파일이 존재")
        }
        do {
            try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try encoder.encode(record)
            try data.write(to: url, options: Self.writeOptions)
        } catch {
            throw StorageError.writeFailed(String(describing: error))
        }
        // 명시적 저장 확인: 다시 읽어 동일한지 확인.
        guard let back = try? decoder.decode(TimeRecord.self, from: Data(contentsOf: url)), back == record else {
            throw StorageError.verificationFailed
        }
    }

    static var writeOptions: Data.WritingOptions {
        #if os(iOS)
        return [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
        #else
        return [.atomic]
        #endif
    }

    public func records(from start: Date, to end: Date) throws -> RecordQueryResult {
        guard start < end else { return RecordQueryResult(records: [], unreadableCount: 0) }
        var results: [TimeRecord] = []
        var unreadable = 0
        for month in Self.monthKeys(from: start, to: end) {
            let dir = recordsDirectory.appendingPathComponent(month, isDirectory: true)
            var isDir: ObjCBool = false
            guard fileManager.fileExists(atPath: dir.path, isDirectory: &isDir) else { continue }
            guard isDir.boolValue else { throw StorageError.readFailed("월 디렉터리가 파일임: \(month)") }
            let names: [String]
            do {
                names = try fileManager.contentsOfDirectory(atPath: dir.path)
            } catch {
                throw StorageError.readFailed(String(describing: error))
            }
            for name in names where name.hasSuffix(".json") {
                let url = dir.appendingPathComponent(name)
                guard let data = try? Data(contentsOf: url),
                      let record = try? decoder.decode(TimeRecord.self, from: data) else {
                    unreadable += 1 // 삭제하지 않는다
                    continue
                }
                if record.occurredAt >= start && record.occurredAt < end {
                    results.append(record)
                }
            }
        }
        results.sort(by: TimeRecord.chronological)
        return RecordQueryResult(records: results, unreadableCount: unreadable)
    }

    /// 구간이 걸치는 UTC 월 키들.
    static func monthKeys(from start: Date, to end: Date) -> [String] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let s = cal.dateComponents([.year, .month], from: start)
        let lastInstant = end.addingTimeInterval(-0.001)
        let e = cal.dateComponents([.year, .month], from: lastInstant)
        var y = s.year!, m = s.month!
        var keys: [String] = []
        while (y, m) <= (e.year!, e.month!) {
            keys.append(String(format: "%04d-%02d", y, m))
            m += 1
            if m > 12 { m = 1; y += 1 }
        }
        return keys
    }
}
