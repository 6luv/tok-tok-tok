import AudioToolbox
import SwiftUI

/// 기록 완료 소리(사용자 결정 2026-11-10, Q07): 저장이 확인된 뒤 짧은 ‘띵’ 한 번.
///
/// System Sound Services(`AudioServicesPlaySystemSound`)로 재생한다. 이 방식은 기기 무음 모드에서
/// 소리를 내지 않으므로 “무음이 아니면 한 번 띵”이 된다. 앱이 무음 스위치 상태를 직접 읽는 공개 API는 없다.
/// 앱이 화면에 없을 때(단축어·뒷면 탭) 실제로 들리는지는 실기기에서 확인해야 하며,
/// 이를 위해 background audio 모드를 추가하지 않는다(CLAUDE.md 구현 제약).
/// 소리 파일 `record-ding.wav`는 이 프로젝트에서 만든 0.35초 사인파 음(외부 소리 아님).
enum RecordSound {
    private static let soundID: SystemSoundID? = {
        guard let url = Bundle.main.url(forResource: "record-ding", withExtension: "wav") else { return nil }
        var id: SystemSoundID = 0
        let status = AudioServicesCreateSystemSoundID(url as CFURL, &id)
        return status == kAudioServicesNoError ? id : nil
    }()

    static func play() {
        guard let soundID else { return }
        AudioServicesPlaySystemSound(soundID)
    }
}

/// 기록 완료 토스트. 단축어 결과(App Intent 스니펫)와 앱 안 기록에 같은 디자인을 쓴다.
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

extension AppAccent {
    /// 앱 밖(App Intent)에서 쓰는 저장된 메인 색.
    static var stored: AppAccent {
        AppAccent(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .amber
    }
}
