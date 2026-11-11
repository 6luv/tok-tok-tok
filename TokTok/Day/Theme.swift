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
    static let shadowLight = dynamic(light: 0xFFFFFF, dark: 0x34343A, alpha: 0.9)
    static let shadowDark = dynamic(light: 0xA9A9B2, dark: 0x000000, lightAlpha: 0.75, darkAlpha: 0.8)

    // MARK: 글자
    static let text = dynamic(light: 0x1C1C1E, dark: 0xEDEDED)
    static let secondaryText = dynamic(light: 0x4F4F55, dark: 0xA6A6AB)
    /// 눈금 라벨·부가 정보 전용
    static let mutedText = dynamic(light: 0x5E5E64, dark: 0x8C8C92)

    static let onAccent = dynamic(light: 0xFFFFFF, dark: 0x141415)

    // MARK: 모서리·모션
    static let controlRadius: CGFloat = 16
    static let boxRadius: CGFloat = 24
    static let cardRadius: CGFloat = 20
    /// 앱 전체 하나의 곡선 cubic-bezier(0.22, 1, 0.36, 1)
    static func ease(_ duration: Double) -> Animation {
        .timingCurve(0.22, 1, 0.36, 1, duration: duration)
    }

    static func dynamic(light: UInt32, dark: UInt32, alpha: CGFloat = 1) -> Color {
        dynamic(light: light, dark: dark, lightAlpha: alpha, darkAlpha: alpha)
    }

    private static func dynamic(light: UInt32, dark: UInt32, lightAlpha: CGFloat, darkAlpha: CGFloat) -> Color {
        #if canImport(UIKit)
        return Color(UIColor { traits in
            traits.userInterfaceStyle == .light ? uiColor(light, alpha: lightAlpha) : uiColor(dark, alpha: darkAlpha)
        })
        #else
        return Color(uiColor(dark, alpha: darkAlpha))
        #endif
    }

    #if canImport(UIKit)
    private static func uiColor(_ v: UInt32, alpha: CGFloat) -> UIColor {
        UIColor(red: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255,
                blue: CGFloat(v & 0xFF) / 255, alpha: alpha)
    }
    #endif
}

// MARK: 메인 색

/// 설정의 ‘메인 색’. 기본은 호박색(사용자 요청 2026-11-10).
/// 색은 면을 채우지 않고 앱 tint(동작 글자·시스템 버튼)와 최신 기록 눈금에만 쓴다.
/// - tint: 글자로 쓰이므로 라이트·다크 모두 바탕 대비 4.5:1 이상
/// - tick: 그래픽 요소라 라이트에서 파인 홈 대비 3:1 이상
enum AppAccent: String, CaseIterable, Identifiable {
    case amber, coral, sage, sky, lavender

    static let storageKey = "toktok.accent"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .amber: "호박"
        case .coral: "산호"
        case .sage: "세이지"
        case .sky: "하늘"
        case .lavender: "라벤더"
        }
    }

    private var values: (dark: UInt32, lightText: UInt32, lightTick: UInt32) {
        switch self {
        case .amber: (0xF0B45A, 0x8A5200, 0xA67218)
        case .coral: (0xFF8F73, 0xA8361C, 0xCE5839)
        case .sage: (0x8FCB9B, 0x2E6B3B, 0x4F885C)
        case .sky: (0x82BDF2, 0x1D5C96, 0x4280BB)
        case .lavender: (0xB9A6F2, 0x5A42A8, 0x836CCF)
        }
    }

    /// 앱 tint(동작 글자)
    var tint: Color { Theme.dynamic(light: values.lightText, dark: values.dark) }
    /// 최신 기록 눈금
    var tick: Color { Theme.dynamic(light: values.lightTick, dark: values.dark) }
}

private struct TokTokAccentKey: EnvironmentKey {
    static let defaultValue: AppAccent = .amber
}

extension EnvironmentValues {
    var tokTokAccent: AppAccent {
        get { self[TokTokAccentKey.self] }
        set { self[TokTokAccentKey.self] = newValue }
    }
}

extension View {
    /// 메인 색을 tint와 환경 값으로 함께 내려 준다.
    func tokTokAccent(_ accent: AppAccent) -> some View {
        tint(accent.tint).environment(\.tokTokAccent, accent)
    }
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

    /// 스크롤 내용을 담는 파인 판. 면은 뒤에, 안쪽 그림자는 위에 얹고, 내용은 판 모양으로 자른다.
    /// 스크롤 중에도 위아래 모서리가 둥글게 유지된다.
    func insetPanel<S: Shape>(_ shape: S, depth: CGFloat = 3) -> some View {
        self
            .clipShape(shape)
            .background(shape.fill(Theme.well))
            .overlay {
                ZStack {
                    shape.stroke(Theme.shadowDark, lineWidth: depth * 1.5)
                        .blur(radius: depth)
                        .offset(x: depth * 0.6, y: depth * 0.6)
                    shape.stroke(Theme.shadowLight, lineWidth: depth * 1.5)
                        .blur(radius: depth)
                        .offset(x: -depth * 0.6, y: -depth * 0.6)
                }
                .mask(shape)
                .allowsHitTesting(false)
            }
    }

    /// 앱 공통 글꼴: SF Pro Rounded(시스템 둥근 글꼴). 한글은 시스템 고딕으로 대체된다.
    func tokTokFont() -> some View {
        fontDesign(.rounded)
    }
}

// MARK: 버튼

/// 보조 버튼: 작은 튀어나온 알약. 누르면 파인다.
struct SecondaryButtonStyle: ButtonStyle {
    /// true면 글자를 메인 색(tint)으로: 설정의 ‘적용’처럼 확정 동작에 쓴다.
    var emphasized = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let shape = Capsule(style: .continuous)
        return configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(emphasized && isEnabled ? AnyShapeStyle(.tint) : AnyShapeStyle(Theme.text))
            .padding(.horizontal, 20)
            .frame(minHeight: 44)
            .modifier(NeuPress(pressed: configuration.isPressed, shape: shape, depth: 4))
            .opacity(isEnabled ? 1 : 0.45)
    }
}

/// 뉴모피즘 켜기·끄기 스위치: 파인 알약 홈 안에서 튀어나온 원이 좌우로 움직인다.
/// 켜지면 원이 오른쪽으로 가고 홈이 메인 색(`tick`)으로 채워진다(사용자 요청 2026-11-11: 옅은 35%가 탁해 보여 불투명하게).
struct NeuToggleStyle: ToggleStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.tokTokAccent) private var accent

    func makeBody(configuration: Configuration) -> some View {
        Button {
            if reduceMotion { configuration.isOn.toggle() } else {
                withAnimation(Theme.ease(0.2)) { configuration.isOn.toggle() }
            }
        } label: {
            HStack(spacing: 12) {
                configuration.label
                    .font(.body)
                    .foregroundStyle(Theme.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    Capsule(style: .continuous)
                        .fill(configuration.isOn ? accent.tick : Color.clear)
                        .frame(width: 56, height: 32)
                        .inset(Capsule(style: .continuous), depth: 3)
                    Circle()
                        .fill(Theme.background)
                        .frame(width: 24, height: 24)
                        .shadow(color: Theme.shadowDark, radius: 3, x: 2, y: 2)
                        .shadow(color: Theme.shadowLight, radius: 3, x: -2, y: -2)
                        .padding(4)
                }
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityValue(configuration.isOn ? "켜짐" : "꺼짐")
        .accessibilityAddTraits(.isToggle)
    }
}

/// 뉴모피즘 분할 선택: 파인 알약 홈 안에서 고른 칸만 튀어나온다.
struct NeuSegmented<Value: Hashable & Identifiable>: View {
    let options: [Value]
    @Binding var selection: Value
    let title: (Value) -> String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options) { option in
                let selected = option == selection
                Button {
                    if reduceMotion { selection = option } else {
                        withAnimation(Theme.ease(0.2)) { selection = option }
                    }
                } label: {
                    Text(title(option))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(selected ? Theme.text : Theme.secondaryText)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background {
                            if selected {
                                Capsule(style: .continuous)
                                    .fill(Theme.background)
                                    .shadow(color: Theme.shadowDark, radius: 5, x: 3, y: 3)
                                    .shadow(color: Theme.shadowLight, radius: 5, x: -3, y: -3)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(title(option))
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(4)
        .inset(Capsule(style: .continuous), depth: 3)
    }
}

/// 주 버튼: 큰 튀어나온 둥근 사각형(모서리 20, 헤더 카드와 같은 계열). 누르면 파인다. 색을 채우지 않는다.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
        return configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(Theme.text)
            .frame(maxWidth: .infinity, minHeight: 64)
            .modifier(NeuPress(pressed: configuration.isPressed, shape: shape, depth: 7))
            .opacity(isEnabled ? 1 : 0.45)
    }
}

/// 확인 창 버튼: 튀어나온 둥근 사각형(모서리 18, 높이 52). 누르면 파인다.
/// emphasized면 글자를 메인 색(tint)으로: ‘N개 지우기’처럼 확정 동작에 쓴다. 빨간색은 쓰지 않는다.
struct DialogButtonStyle: ButtonStyle {
    var emphasized = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        return configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(emphasized && isEnabled ? AnyShapeStyle(.tint) : AnyShapeStyle(Theme.text))
            .frame(maxWidth: .infinity, minHeight: 52)
            .modifier(NeuPress(pressed: configuration.isPressed, shape: shape, depth: 5))
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

// MARK: 설정·안내 화면

/// 설정·안내 화면의 바탕: 스크롤 + 카드 묶음. 시스템 List 대신 뉴모피즘 카드를 쓴다.
struct NeuPage<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                content
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Theme.background)
    }
}

/// 머리글·카드·꼬리말 한 묶음. 카드는 튀어나온 면이다.
struct NeuSection<Content: View, Header: View, Footer: View>: View {
    let content: Content
    let header: Header
    let footer: Footer
    /// true면 행 목록 카드: 위아래 안쪽 4, 행 사이 0(행 높이 44가 간격을 맡음). 사용자 요청 2026-11-11
    var compact = false

    init(compact: Bool = false,
         @ViewBuilder content: () -> Content,
         @ViewBuilder header: () -> Header,
         @ViewBuilder footer: () -> Footer) {
        self.compact = compact
        self.content = content()
        self.header = header()
        self.footer = footer()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
                .font(.footnote.weight(.medium))
                .foregroundStyle(Theme.secondaryText)
                .padding(.leading, 4)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: compact ? 0 : 12) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, compact ? 4 : 16)
            .extruded(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous), depth: 5)
            footer
                .font(.footnote)
                .foregroundStyle(Theme.mutedText)
                .padding(.horizontal, 4)
        }
    }
}

extension NeuSection where Footer == EmptyView {
    init(compact: Bool = false, @ViewBuilder content: () -> Content, @ViewBuilder header: () -> Header) {
        self.init(compact: compact, content: content, header: header, footer: { EmptyView() })
    }
}

extension NeuSection where Header == EmptyView, Footer == EmptyView {
    init(compact: Bool = false, @ViewBuilder content: () -> Content) {
        self.init(compact: compact, content: content, header: { EmptyView() }, footer: { EmptyView() })
    }
}

/// 카드 안의 다음 화면 이동 행.
struct NeuLinkRow<Destination: View>: View {
    let title: String
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Text(title).foregroundStyle(Theme.text)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.mutedText)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
