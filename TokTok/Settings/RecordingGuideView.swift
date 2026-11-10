import AppIntents
import Combine
import SwiftUI
import TokTokCore

/// 뒷면 탭 연결 도우미(R03).
///
/// 앱이 할 수 있는 것: 미리 만든 ‘톡톡톡’ 단축어의 iCloud 공유 링크 열기(단축어 앱이 열리고 사용자가 ‘단축어 추가’를 누름),
/// 단축어 앱의 TokTok 페이지 열기(`ShortcutsLink`, iOS 16+),
/// 새 단축어 편집기 열기(`shortcuts://create-shortcut`, Apple 단축어 사용 설명서의 URL 스킴),
/// 연결 후 마지막 단축어 기록을 보여 줘 사용자가 직접 확인하게 하기.
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
                .padding(.horizontal, 4)

            stepCard(1, title: Self.sharedShortcutURL == nil ? "단축어 만들기" : "단축어 받기", done: false) {
                if let shared = Self.sharedShortcutURL {
                    detail("단축어 앱이 열리면 ‘단축어 추가’를 눌러요")
                    Button {
                        openURL(shared)
                    } label: {
                        Label("‘\(Self.suggestedShortcutName)’ 받기", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(SecondaryButtonStyle(emphasized: true))
                    .accessibilityHint("단축어 앱에서 \(Self.suggestedShortcutName) 단축어를 추가해요")
                } else {
                    detail("새 단축어 → 동작 추가에서 ‘TokTokTok’을 찾아 ‘현재 시간 기록’을 넣고, 이름을 ‘\(Self.suggestedShortcutName)’로 저장해요")
                    Button {
                        if let url = URL(string: "shortcuts://create-shortcut") { openURL(url) }
                    } label: {
                        Label("단축어 앱에서 만들기", systemImage: "plus")
                    }
                    .buttonStyle(SecondaryButtonStyle(emphasized: true))
                    HStack(spacing: 8) {
                        Text("동작 미리 보기")
                            .font(.footnote)
                            .foregroundStyle(Theme.mutedText)
                        ShortcutsLink()
                    }
                }
            }

            stepCard(2, title: "뒷면 탭에 연결", done: false) {
                detail("설정 앱에서 아래 순서로 들어가 ‘\(Self.suggestedShortcutName)’를 골라요. TokTokTok이 대신 열 수는 없어요.")
                pathChips(["설정", "손쉬운 사용", "터치", "뒷면 탭", "두 번 탭", Self.suggestedShortcutName])
                Text("메뉴 이름은 iOS 버전에 따라 조금 다를 수 있어요")
                    .font(.footnote)
                    .foregroundStyle(Theme.mutedText)
            }

            stepCard(3, title: "시험하기", done: latest != nil) {
                detail("화면이 켜진 상태에서 뒷면을 톡톡 친 뒤 이 화면으로 돌아와요")
                verification
            }

            NeuSection {
                note("clock", "기록 시각은 단축어가 실행된 순간이라 탭한 순간과 조금 다를 수 있어요")
                note("rectangle.topthird.inset.filled", "실행할 때 iOS가 화면 위에 실행 중 표시를 띄워요")
                note("moon", "화면이 꺼져 있으면 뒷면 탭이 인식되지 않아요(실기기 확인). 이때는 Siri에게 “TokTokTok 기록”이라고 말해 보세요.")
                note("hand.tap", "앱 안 ‘현재 시간 기록’ 버튼은 연결 없이 언제든 쓸 수 있어요")
            } header: {
                Text("알아 두세요")
            } footer: {
                Text("뒷면 탭·Siri 기록은 앱에서 모두 ‘단축어 기록’으로 구분돼요")
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

    // MARK: 단계 카드

    /// 번호 원(튀어나옴, 완료면 파이고 체크) + 제목 + 내용. 카드는 튀어나온 면.
    private func stepCard<Content: View>(_ n: Int, title: String, done: Bool,
                                         @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top, spacing: 12) {
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

            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Theme.text)
                    .frame(minHeight: 32, alignment: .leading)
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .extruded(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous), depth: 5)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(n)단계. \(title)\(done ? ", 완료" : "")")
    }

    private func detail(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Theme.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// 설정 앱 경로를 순서대로 파인 칩으로 보여 준다.
    private func pathChips(_ items: [String]) -> some View {
        WrapLayout(spacing: 6, lineSpacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(spacing: 6) {
                    Text(item)
                        .font(.footnote.weight(index == items.count - 1 ? .semibold : .regular))
                        .foregroundStyle(index == items.count - 1 ? AnyShapeStyle(.tint) : AnyShapeStyle(Theme.text))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .inset(Capsule(style: .continuous), depth: 2)
                    if index < items.count - 1 {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.mutedText)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(items.joined(separator: ", "))
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
                let p = DayPresentation(timeZone: .current)
                let block = p.blocks(for: [latest])[0]
                VStack(alignment: .leading, spacing: 4) {
                    Text("마지막 단축어 기록")
                        .font(.caption)
                        .foregroundStyle(Theme.mutedText)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(block.timeText)
                            .font(.system(.title2, design: .rounded).weight(.light).monospacedDigit())
                            .foregroundStyle(Theme.text)
                        Text(block.dateText)
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    Text("방금 친 시각과 다르면 2단계를 다시 확인해 주세요")
                        .font(.footnote)
                        .foregroundStyle(Theme.mutedText)
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

        Button {
            Task { await refresh() }
        } label: {
            Label("다시 확인", systemImage: "arrow.clockwise")
        }
        .buttonStyle(SecondaryButtonStyle())
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

/// 칩을 줄바꿈하며 배치(iOS 16+ Layout).
private struct WrapLayout: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineH: CGFloat = 0, maxX: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x > 0, x + s.width > width { y += lineH + lineSpacing; x = 0; lineH = 0 }
            x += s.width + spacing; lineH = max(lineH, s.height); maxX = max(maxX, x - spacing)
        }
        return CGSize(width: min(maxX, width), height: y + lineH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, lineH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x > bounds.minX, x + s.width > bounds.maxX { y += lineH + lineSpacing; x = bounds.minX; lineH = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing; lineH = max(lineH, s.height)
        }
    }
}
