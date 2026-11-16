import Foundation

/// 기록이 들어온 실행 경로. 실제로 알 수 있는 경로만 저장한다.
/// 동일 App Intent가 단축어·Siri·뒷면 탭 중 무엇에서 호출됐는지는 추정하지 않는다(모두 `.intent`).
public enum RecordSource: String, Codable, Sendable {
    case app
    case intent
    case unknown

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = RecordSource(rawValue: raw) ?? .unknown
    }
}

/// 한 번의 사용자 실행으로 생긴 시간 기록. 원본 값은 저장 후 수정하지 않는다.
public struct TimeRecord: Codable, Hashable, Identifiable, Sendable {
    public static let currentSchemaVersion = 1

    /// 기록 ID이자 내부 재시도용 작업 ID. 같은 ID의 재저장은 한 건으로 처리한다.
    public let id: UUID
    /// 절대 시각(처리 진입 시 한 번 읽은 값).
    public let occurredAt: Date
    /// 기록 당시 기기 시간대 ID.
    public let recordedTimeZoneID: String
    /// 기록 당시 UTC 오프셋(초).
    public let recordedUTCOffsetSeconds: Int
    public let source: RecordSource
    public let schemaVersion: Int

    public init(id: UUID, occurredAt: Date, timeZone: TimeZone, source: RecordSource) {
        self.id = id
        self.occurredAt = occurredAt
        self.recordedTimeZoneID = timeZone.identifier
        self.recordedUTCOffsetSeconds = timeZone.secondsFromGMT(for: occurredAt)
        self.source = source
        self.schemaVersion = TimeRecord.currentSchemaVersion
    }
}

extension TimeRecord {
    /// 같은 시각 기록의 안정된 정렬(T15): 시각 → ID.
    public static func chronological(_ a: TimeRecord, _ b: TimeRecord) -> Bool {
        if a.occurredAt != b.occurredAt { return a.occurredAt < b.occurredAt }
        return a.id.uuidString < b.id.uuidString
    }
}
