import AppIntents
import Foundation
import TokTokTokCore

/// 입력 없는 "현재 시간 기록" 액션 (R02).
///
/// - 실행 모드: `openAppWhenRun`(iOS 26 deprecated)과 `supportedModes`(iOS 26+)를 선언하지 않고
///   기본 동작(앱을 전면에 열지 않음)에 맡긴다. 최소 iOS 17 호환을 위해서다.
/// - 인증: `.alwaysAllowed`(기본값과 같음). 이는 OS가 잠금 상태에서 실행을 허용할 수 있다는 정책일 뿐,
///   실제 트리거 전달·파일 보호 접근 가능 여부는 별개이며 실기기 검증 전에는 보장하지 않는다.
/// - 기록 시각은 perform 진입 직후 서비스가 한 번 읽는다. 물리적 탭 시각이 아니다.
/// - 단축어·뒷면 탭 등 어느 경로인지 추정하지 않고 source = .intent로 저장한다(앱이 Siri 안내는 하지 않는다).
/// - 결과: 아무 대화·스니펫도 돌려주지 않는다(사용자 결정 2026-11-10). 뒷면 탭·단축어 실행 중이라는
///   iOS 자체 표시가 이미 보이므로 앱 결과 토스트를 겹쳐 띄우지 않는다. 실패는 오류로 알린다.
/// - 저장 확인 뒤 기기 기본 진동 한 번(`RecordHaptic`)과 짧은 소리 한 번(`RecordSound`, 무음 모드에서는 무음). 설정에서 각각 끌 수 있다(사용자 결정 2026-11-11).
struct RecordNowIntent: AppIntent {
    static var title: LocalizedStringResource = "현재 시간 기록"
    static var description = IntentDescription("지금 이 순간의 시각을 TokTokTok에 기록합니다. 입력할 값은 없습니다.")
    static var authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    init() {}

    func perform() async throws -> some IntentResult {
        let service: RecordTimeService
        do {
            service = try RecordTimeService.live()
        } catch {
            throw RecordIntentError.storageUnavailable
        }
        do {
            let record = try service.recordNow(source: .intent)
            // 저장이 확인된 뒤에만 알린다.
            RecordsChangeNotifier.post()
            RecordHaptic.vibrate()
            RecordSound.play()
            return .result()
        } catch RecordError.boundaryNotConfigured {
            throw RecordIntentError.boundaryNotConfigured
        } catch RecordError.saveFailed {
            throw RecordIntentError.saveFailed
        } catch {
            throw RecordIntentError.storageUnavailable
        }
    }
}

enum RecordIntentError: Error, CustomLocalizedStringResourceConvertible {
    case boundaryNotConfigured
    case saveFailed
    case storageUnavailable

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .boundaryNotConfigured:
            return "아직 하루 시작 시간을 정하지 않았어요. TokTokTok 앱을 열어 초기 설정을 마친 뒤 다시 실행해 주세요. 이번 실행은 기록되지 않았어요."
        case .saveFailed:
            return "기록을 저장하지 못했어요. 이번 실행은 기록되지 않았어요. 다시 실행해 주세요."
        case .storageUnavailable:
            return "저장소에 접근하지 못했어요. 이번 실행은 기록되지 않았어요. 기기 잠금을 해제한 뒤 다시 실행해 주세요."
        }
    }
}

enum IntentFormatting {
    static func timeText(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = TimeZone.current
        f.dateFormat = "HH:mm:ss"
        return f.string(from: date)
    }
}
