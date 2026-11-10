import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// 디자인 토큰(DESIGN.md ‘토큰’ 절과 같은 값). 대비 계산은 TEST_RESULTS.md R-009.
///
/// 방향: 뉴모피즘. 회색 한 톤의 바탕에서 면이 튀어나오거나(extruded) 파인(inset) 것처럼
/// 밝은 그림자(위·왼쪽)와 어두운 그림자(아래·오른쪽)로만 깊이를 만든다.
/// 색은 최신 기록 눈금의 호박색 하나뿐이고, 글자는 대비를 위해 충분히 진하게 둔다.
/// 모든 색은 다크·라이트 두 벌이며 시스템 색 모드(설정의 ‘화면 모드’)에 따라 바뀐다.
enum Theme {
    // MARK: 면
    /// 화면 바탕이자 튀어나온 면의 색(뉴모피즘은 면과 바탕이 같은 색이다)
    static let background = dynamic(light: 0xE6E6E9, dark: 0x202023)
    /// 목록 행·카드. 바탕과 같다.
    static let surface = background
    /// 파인 홈 안쪽
    static let well = dynamic(light: 0xDDDDE1, dark: 0x1A1A1D)
    /// 보조 면(설정 목록 행)
    static let raised = dynamic(light: 0xEEEEF1, dark: 0x27272B)
    /// 구분선·테두리
    static let hairline = dynamic(light: 0x1C1C1E, dark: 0xEDEDED, alpha: 0.08)

    // MARK: 그림자
    static let shadowLight = dynamic(light: 0xFFFFFF, dark: 0x2F2F34, alpha: 0.9)
    static let shadowDark = dynamic(light: 0xA9A9B2, dark: 0x0A0A0B, alpha: 0.75)

    // MARK: 글자
    static let text = dynamic(light: 0x1C1C1E, dark: 0xEDEDED)
    static let secondaryText = dynamic(light: 0x4F4F55, dark: 0xA6A6AB)
    /// 눈금 라벨·부가 정보 전용
    static let mutedText = dynamic(light: 0x5E5E64, dark: 0x8C8C92)

    // MARK: 강조
    /// 최신 기록 눈금·앱 tint. 면 채우기에는 쓰지 않는다.
    static let accent = dynamic(light: 0x8A5200, dark: 0xF0B45A)
    static let onAccent = dynamic(light: 0xFFFFFF, dark: 0x141415)

    // MARK: 모서리·모션
    static let controlRadius: CGFloat = 16
    static let boxRadius: CGFloat = 24
    /// 앱 전체 하나의 곡선 cubic-bezier(0.22, 1, 0.36, 1)
    static func ease(_ duration: Double) -> Animation {
        .timingCurve(0.22, 1, 0.36, 1, duration: duration)
    }

    private static func dynamic(light: UInt32, dark: UInt32, alpha: CGFloat = 1) -> Color {
        #if canImport(UIKit)
        return Color(UIColor { traits in
            uiColor(traits.userInterfaceStyle == .light ? light : dark, alpha: alpha)
        })
        #else
        return Color(uiColor(dark, alpha: alpha))
        #endif
    }

    #if canImport(UIKit)
    private static func uiColor(_ v: UInt32, alpha: CGFloat) -> UIColor {
        UIColor(red: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255,
                blue: CGFloat(v & 0xFF) / 255, alpha: alpha)
    }
    #endif
}

// MARK: 화면 모드

/// 설정의 ‘화면 모드’. 기본은 다크(Q11 결정 2026-11-10: 다크·라이트 선택, 기본 다크).
enum AppAppearance: String, CaseIterable, Identifiable {
    case dark
    case light

    static let storageKey = "toktok.appearance"

    var id: String { rawValue }
    var title: String { self == .dark ? "다크" : "라이트" }
    var colorScheme: ColorScheme { self == .dark ? .dark : .light }
}

// MARK: 뉴모피즘 면

extension View {
    /// 바탕에서 튀어나온 면.
    func extruded<S: Shape>(_ shape: S, depth: CGFloat = 6) -> some View {
        background {
            shape.fill(Theme.background)
                .shadow(color: Theme.shadowDark, radius: depth * 1.6, x: depth, y: depth)
                .shadow(color: Theme.shadowLight, radius: depth * 1.6, x: -depth, y: -depth)
        }
    }

    /// 바탕에 파인 홈.
    func inset<S: Shape>(_ shape: S, depth: CGFloat = 4) -> some View {
        background {
            shape.fill(Theme.well)
                .overlay {
                    shape.stroke(Theme.shadowDark, lineWidth: depth * 1.5)
                        .blur(radius: depth)
                        .offset(x: depth * 0.6, y: depth * 0.6)
                        .mask(shape)
                }
                .overlay {
                    shape.stroke(Theme.shadowLight, lineWidth: depth * 1.5)
                        .blur(radius: depth)
                        .offset(x: -depth * 0.6, y: -depth * 0.6)
                        .mask(shape)
                }
        }
    }

    /// 설정·안내 목록의 공통 면 처리.
    func tokTokListStyle() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .listRowSeparatorTint(Theme.hairline)
    }
}

// MARK: 버튼

/// 보조 버튼: 작은 튀어나온 알약. 누르면 파인다.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let shape = Capsule(style: .continuous)
        return configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 20)
            .frame(minHeight: 44)
            .modifier(NeuPress(pressed: configuration.isPressed, shape: shape, depth: 4))
    }
}

/// 주 버튼: 큰 튀어나온 알약. 누르면 파인다. 색을 채우지 않는다.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let shape = Capsule(style: .continuous)
        return configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(Theme.text)
            .frame(maxWidth: .infinity, minHeight: 64)
            .modifier(NeuPress(pressed: configuration.isPressed, shape: shape, depth: 7))
            .opacity(isEnabled ? 1 : 0.45)
    }
}

/// 원형 아이콘 버튼(설정 톱니 등).
struct CircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .regular))
            .foregroundStyle(Theme.secondaryText)
            .frame(width: 44, height: 44)
            .modifier(NeuPress(pressed: configuration.isPressed, shape: Circle(), depth: 4))
    }
}

private struct NeuPress<S: Shape>: ViewModifier {
    let pressed: Bool
    let shape: S
    let depth: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        Group {
            if pressed {
                content.inset(shape, depth: depth * 0.7)
            } else {
                content.extruded(shape, depth: depth)
            }
        }
        .contentShape(shape)
        .animation(reduceMotion ? nil : Theme.ease(0.15), value: pressed)
    }
}
