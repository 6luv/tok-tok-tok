import AudioToolbox
import SwiftUI

/// 기록 완료 진동(사용자 결정 2026-11-11, Q07): 저장이 확인된 뒤 기기 기본 진동 한 번. 소리는 `RecordSound`.
///
/// `kSystemSoundID_Vibrate`(Audio Toolbox 공개 상수)를 쓴다. 기기의 손쉬운 사용 › 터치 › 진동이 꺼져 있으면
/// iOS가 울리지 않는다. 앱이 화면에 없을 때(뒷면 탭·단축어) 실제로 울리는지는 실기기 확인 대상이며,
/// 이를 위해 background 모드를 추가하지 않는다(CLAUDE.md 구현 제약).
/// 앱 설정의 ‘진동’ 토글(`storageKey`, 기본 켜짐)이 꺼져 있으면 진동 명령을 보내지 않는다(2026-11-11).
/// 기기 설정(손쉬운 사용 › 터치 › 진동 등)이 진동을 막으면 앱이 이를 무시할 수 없다.
enum RecordHaptic {
    static let storageKey = "toktok.vibration"

    /// 저장된 값이 없으면 켜짐.
    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: storageKey) as? Bool ?? true
    }

    static func vibrate() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}

/// 기록 완료 소리(사용자 결정 2026-11-11, Q07): 저장 확인 뒤 짧은 마림바 소리 한 번.
///
/// 소리 파일 `record-sound.wav`는 이 프로젝트에서 만든 0.45초 합성음(외부·Apple 소리 아님).
/// System Sound Services(`AudioServicesCreateSystemSoundID`·`AudioServicesPlaySystemSound`, 공개 API)로 재생해
/// 기기가 무음 모드면 iOS가 소리를 내지 않는다(진동은 `RecordHaptic`이 따로 처리).
/// 앱 설정의 ‘기록할 때 소리’(`storageKey`, 기본 켜짐)가 꺼져 있으면 재생하지 않는다.
/// 앱이 화면에 없을 때(뒷면 탭·단축어) 실제로 들리는지는 실기기 확인 대상이며 background 모드는 추가하지 않는다.
enum RecordSound {
    static let storageKey = "toktok.sound"

    /// 저장된 값이 없으면 켜짐.
    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: storageKey) as? Bool ?? true
    }

    private static let soundID: SystemSoundID? = {
        guard let url = Bundle.main.url(forResource: "record-sound", withExtension: "wav") else { return nil }
        var id: SystemSoundID = 0
        return AudioServicesCreateSystemSoundID(url as CFURL, &id) == kAudioServicesNoError ? id : nil
    }()

    static func play() {
        guard isEnabled, let soundID else { return }
        AudioServicesPlaySystemSound(soundID)
    }
}

/// 앱 안 기록 완료 토스트. 단축어 결과에는 쓰지 않는다(iOS 실행 표시와 겹치지 않게, 2026-11-10).
/// 소리는 내지 않는다(사용자 결정 2026-11-10: 새벽에 울리면 안 됨).
/// 튀어나온 둥근 카드 + 메인 색 눈금 + 얇은 둥근 시각 숫자.
struct RecordToastView: View {
    let date: Date
    @Environment(\.tokTokAccent) private var accent

    var body: some View {
        HStack(spacing: 12) {
            Capsule()
                .fill(accent.tick)
                .frame(width: 3, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                let t = Self.time.string(from: date)
                (Text(t.prefix(5)).foregroundStyle(Theme.text)
                 + Text(t.dropFirst(5)).foregroundStyle(Theme.secondaryText))
                    .font(.system(.title2, design: .rounded).weight(.light).monospacedDigit())
                Text("\(Self.day.string(from: date)) 기록했어요")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer(minLength: 0)
            Image(systemName: "checkmark")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.secondaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Self.spoken.string(from: date)) 기록했어요")
    }

    private static func formatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = format
        return f
    }

    // 매번 만들어 현재 기기 시간대를 따른다(토스트는 드물게 그려진다).
    private static var time: DateFormatter { formatter("HH:mm:ss") }
    private static var day: DateFormatter { formatter("M월 d일") }
    private static var spoken: DateFormatter { formatter("a h시 m분 s초") }
}
