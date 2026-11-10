import SwiftUI

/// 디자인 토큰(DESIGN.md ‘토큰’ 절과 같은 값). 대비 계산은 TEST_RESULTS.md R-004.
///
/// 방향: 어두운 방 머리맡의 탁상시계. 면·글자는 회색(graphite) 한 줄기에서 고르고,
/// 색은 무드등 같은 호박색 강조 하나만 쓴다. 강조는 기록 버튼, 최신 기록 눈금, 동작 글자에만 쓴다.
enum Theme {
    // MARK: 면
    /// 화면 바탕
    static let background = hex(0x0F0F10)
    /// 기록 블록·목록 행
    static let surface = hex(0x19191B)
    /// 한 단계 올라온 면: 보조 버튼, 알림 상자
    static let raised = hex(0x232325)
    /// 구분선·테두리: 본문색 8%
    static let hairline = hex(0xEDEDED).opacity(0.08)

    // MARK: 글자
    static let text = hex(0xEDEDED)
    static let secondaryText = hex(0xA1A1A6)
    /// 눈금 라벨·부가 정보 전용
    static let mutedText = hex(0x85858B)

    // MARK: 강조
    /// 무드등 호박색
    static let accent = hex(0xF0B45A)
    /// 강조색 면 위 글자
    static let onAccent = hex(0x141415)

    // MARK: 모서리·모션
    static let controlRadius: CGFloat = 12
    static let boxRadius: CGFloat = 16
    /// 앱 전체 하나의 곡선 cubic-bezier(0.22, 1, 0.36, 1)
    static func ease(_ duration: Double) -> Animation {
        .timingCurve(0.22, 1, 0.36, 1, duration: duration)
    }

    private static func hex(_ value: UInt32) -> Color {
        Color(red: Double((value >> 16) & 0xFF) / 255,
              green: Double((value >> 8) & 0xFF) / 255,
              blue: Double(value & 0xFF) / 255)
    }
}

/// 보조 버튼: 올라온 면 + 가는 테두리 + 본문색 글자.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .background(Theme.raised.opacity(configuration.isPressed ? 0.7 : 1),
                        in: RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous)
                .strokeBorder(Theme.hairline))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(Theme.ease(0.15), value: configuration.isPressed)
    }
}

/// 주 버튼: 화면에서 하나뿐인 강조색 면.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(Theme.onAccent)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Theme.accent.opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.4),
                        in: RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(Theme.ease(0.15), value: configuration.isPressed)
    }
}

extension View {
    /// 설정·안내 목록의 공통 면 처리.
    func tokTokListStyle() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .listRowSeparatorTint(Theme.hairline)
    }
}
