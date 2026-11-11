import AppIntents
import Combine
import SwiftUI
import TokTokCore

/// 뒷면 탭 연결 도우미(R03).
///
/// 앱이 할 수 있는 것: 미리 만든 ‘톡톡톡’ 단축어의 iCloud 공유 링크 열기(단축어 앱이 열리고 사용자가 ‘단축어 추가’를 누름),
/// 새 단축어 편집기 열기(`shortcuts://create-shortcut`, Apple 단축어 사용 설명서의 URL 스킴),
/// 연결 후 마지막 단축어 기록을 보여 줘 사용자가 직접 확인하게 하기.
/// `ShortcutsLink`(단축어 앱의 앱 페이지)는 2026-11-10 제거했다. 그 페이지의 자동 단축어를 지우면 버튼이 사라져
/// 사용자가 어떻게 하라는 건지 헷갈렸다. 직접 만드는 단축어에는 영향이 없다.
/// 앱이 할 수 없는 것: 손쉬운 사용 > 뒷면 탭 설정 화면을 열거나 값을 바꾸기, 연결 여부 자동 확인.
/// 공개되지 않은 설정 URL은 사용하지 않는다.
struct RecordingGuideView: View {
    static let suggestedShortcutName = "톡톡톡"

    /// 미리 만든 ‘톡톡톡’ 단축어(동작: TokTokTok › 현재 시간 기록)의 iCloud 공유 링크.
    /// 비어 있으면 받기 버튼을 숨기고 직접 만드는 방법만 보여 준다.
    /// 링크의 단축어에는 개인 정보가 들어가지 않게 한다(공유 링크는 누구나 열 수 있음).
    static let sharedShortcutLink: String? = nil

    static var sharedShortcutURL: URL? {
        guard let link = sharedShortcutLink, let url = URL(string: link),
              url.scheme == "https", url.host == "www.icloud.com", url.path.hasPrefix("/shortcuts/")
        else { return nil }
        return url
    }

    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var latest: TimeRecord?
    @State private var checkedAt: Date?

    var body: some View {
        NeuPage {
            Text("뒷면을 톡톡 치면 지금 시각이 기록되도록 한 번만 연결해요")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)

            // 1. 단축어
            stepCard(1, title: Self.sharedShortcutURL == nil ? "단축어 만들기" : "단축어 받기", done: false) {
                if let shared = Self.sharedShortcutURL {
                    subSteps(["아래 버튼을 눌러요", "단축어 앱에서 ‘단축어 추가’를 눌러요"])
                    actionButton("‘\(Self.suggestedShortcutName)’ 받기", icon: "square.and.arrow.down") { openURL(shared) }
                } else {
                    subSteps([
                        "아래 버튼으로 단축어 앱의 새 단축어를 열어요",
                        "‘동작 추가’에서 ‘TokTokTok’을 검색해요",
                        "‘현재 시간 기록’을 눌러 넣어요",
                        "이름을 ‘\(Self.suggestedShortcutName)’로 바꾸고 완료를 눌러요",
                    ])
                    actionButton("단축어 앱 열기", icon: "arrow.up.forward.app") {
                        if let url = URL(string: "shortcuts://create-shortcut") { openURL(url) }
                    }
                }
            }

            // 2. 뒷면 탭
            stepCard(2, title: "뒷면 탭에 연결", done: false) {
                Text("설정 앱에서 아래 순서로 들어가요")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                settingsPath(["설정", "손쉬운 사용", "터치", "뒷면 탭", "두 번 탭", "‘\(Self.suggestedShortcutName)’ 선택"])
                Text("TokTokTok이 설정 화면을 대신 열 수는 없어요. 메뉴 이름은 iOS 버전에 따라 조금 다를 수 있어요.")
                    .font(.footnote)
                    .foregroundStyle(Theme.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // 3. 시험
            stepCard(3, title: "시험하기", done: latest != nil) {
                Text("화면이 켜진 상태에서 뒷면을 톡톡 친 뒤 이 화면으로 돌아와요")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                verification
            }

            NeuSection {
                note("clock", "기록 시각은 단축어가 실행된 순간이라 탭한 순간과 조금 다를 수 있어요")
                note("rectangle.topthird.inset.filled", "실행할 때 iOS가 화면 위에 실행 중 표시를 띄워요")
                note("moon", "화면이 꺼져 있으면 뒷면 탭이 인식되지 않아요. 이때는 Siri에게 “TokTokTok 기록”이라고 말해 보세요.")
                note("hand.tap", "앱 안 ‘현재 시간 기록’ 버튼은 연결 없이 언제든 쓸 수 있어요")
            } header: {
                Text("알아 두세요")
            }
        }
        .navigationTitle("뒷면 탭 연결")
        .navigationBarTitleDisplayMode(.inline)
        .task { await refresh() }
        .onChange(of: scenePhase) { _, phase in
            // 설정 앱에서 시험 탭 후 돌아오면 다시 확인
            if phase == .active { Task { await refresh() } }
        }
        .onReceive(NotificationCenter.default.publisher(for: RecordsChangeNotifier.name).receive(on: RunLoop.main)) { _ in
            Task { await refresh() }
        }
    }

    // MARK: 구성 요소

    /// 단계 카드: 위에 번호 원 + 제목, 아래에 내용(카드 전체 폭). 큰 글씨·좁은 화면에서도 세로로만 늘어난다.
    private func stepCard<Content: View>(_ n: Int, title: String, done: Bool,
                                         @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    if done {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.tint)
                    } else {
                        Text("\(n)")
                            .font(.subheadline.weight(.medium).monospacedDigit())
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                .frame(width: 32, height: 32)
                .modifier(StepBadge(done: done))
                .accessibilityHidden(true)
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Theme.text)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityLabel("\(n)단계. \(title)\(done ? ", 완료" : "")")
                Spacer(minLength: 0)
            }
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .extruded(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous), depth: 5)
    }

    /// 작은 순서 목록: 흐린 숫자 + 한 줄 설명.
    private func subSteps(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(index + 1).")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Theme.mutedText)
                        .frame(minWidth: 20, alignment: .leading)
                    Text(item)
                        .font(.subheadline)
                        .foregroundStyle(Theme.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    /// 설정 앱 경로: 파인 홈 안에 한 줄씩 세로로. 마지막 줄은 메인 색.
    private func settingsPath(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                let last = index == items.count - 1
                HStack(spacing: 8) {
                    Image(systemName: index == 0 ? "gearshape" : "arrow.turn.down.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.mutedText)
                        .frame(width: 20)
                    Text(item)
                        .font(.subheadline.weight(last ? .medium : .regular))
                        .foregroundStyle(last ? AnyShapeStyle(.tint) : AnyShapeStyle(Theme.text))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(.leading, CGFloat(min(index, 1)) * 4)
                .frame(minHeight: 32)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .inset(RoundedRectangle(cornerRadius: 12, style: .continuous), depth: 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(items.joined(separator: ", "))
    }

    private func actionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(SecondaryButtonStyle(emphasized: true))
    }

    private func note(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Theme.mutedText)
                .frame(width: 20)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var verification: some View {
        Group {
            if let latest {
                let block = DayPresentation(timeZone: .current).blocks(for: [latest])[0]
                VStack(alignment: .leading, spacing: 4) {
                    Text("마지막 단축어 기록")
                        .font(.caption)
                        .foregroundStyle(Theme.mutedText)
                    Text(block.timeText)
                        .font(.system(.title2, design: .rounded).weight(.light).monospacedDigit())
                        .foregroundStyle(Theme.text)
                    Text("\(block.dateText) · 방금 친 시각과 다르면 2단계를 다시 확인해 주세요")
                        .font(.footnote)
                        .foregroundStyle(Theme.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            } else if checkedAt != nil {
                Text("아직 단축어 기록이 없어요(최근 2주)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .inset(RoundedRectangle(cornerRadius: 12, style: .continuous), depth: 3)

        actionButton("다시 확인", icon: "arrow.clockwise") { Task { await refresh() } }
    }

    private func refresh() async {
        let found: TimeRecord? = await Task.detached {
            try? RecordTimeService.live().latestRecord(source: .intent)
        }.value
        latest = found
        checkedAt = Date()
    }
}

private struct StepBadge: ViewModifier {
    let done: Bool
    func body(content: Content) -> some View {
        if done { content.inset(Circle(), depth: 2) } else { content.extruded(Circle(), depth: 3) }
    }
}
