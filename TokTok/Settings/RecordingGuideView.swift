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
            NeuSection {
                Text("뒷면을 톡톡 치면 지금 시각이 기록되도록 한 번만 연결해요")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            }

            NeuSection {
                if let shared = Self.sharedShortcutURL {
                    stepRow(1, "‘\(Self.suggestedShortcutName)’ 단축어 받기")
                    Text("단축어 앱이 열리면 ‘단축어 추가’를 눌러요")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryText)
                    Button {
                        openURL(shared)
                    } label: {
                        Label("‘\(Self.suggestedShortcutName)’ 받기", systemImage: "square.and.arrow.down")
                            .frame(minHeight: 44)
                    }
                    .foregroundStyle(.tint)
                    .font(.body.weight(.medium))
                    .accessibilityHint("단축어 앱에서 \(Self.suggestedShortcutName) 단축어를 추가해요")
                } else {
                    manualShortcutSteps
                }
            } header: {
                Text("1. 단축어 준비")
            }

            NeuSection {
                stepRow(2, "설정 앱 → 손쉬운 사용 → 터치 → 뒷면 탭")
                stepRow(3, "‘두 번 탭’ 또는 ‘세 번 탭’ 선택")
                stepRow(4, "단축어 목록에서 ‘\(Self.suggestedShortcutName)’ 선택")
                Text("설정 앱에서 직접 바꿔야 해요. 메뉴 이름은 iOS 버전에 따라 다를 수 있어요.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
            } header: {
                Text("2. 뒷면 탭에 연결")
            }

            NeuSection {
                stepRow(5, "뒷면을 톡톡 쳐 본 뒤 이 화면으로 돌아오기")
                verification
            } header: {
                Text("3. 연결 확인")
            } footer: {
                Text("뒷면 탭·Siri 기록도 모두 ‘단축어 기록’으로 보여요")
            }

            NeuSection {
                Text("기록 시각은 단축어가 실행된 순간이라 탭한 순간과 조금 다를 수 있어요")
                Text("실행할 때 iOS가 화면 위에 짧은 알림을 띄울 수 있어요")
                Text("화면이 꺼져 있으면 뒷면 탭이 인식되지 않아요(실기기 확인)")
                Text("화면이 꺼졌을 때는 Siri에게 “TokTokTok 기록”이라고 말해 보세요. 잠금 상태 동작은 기기마다 다를 수 있어요.")
                Text("앱 안 ‘현재 시간 기록’ 버튼은 연결 없이 언제든 쓸 수 있어요")
            } header: {
                Text("알아 두세요")
            }
            .font(.subheadline)
            .foregroundStyle(Theme.secondaryText)
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

    /// 공유 링크가 없을 때: 사용자가 단축어 앱에서 직접 만든다.
    @ViewBuilder
    private var manualShortcutSteps: some View {
        stepRow(1, "단축어 앱에서 ‘\(Self.suggestedShortcutName)’ 단축어 만들기")
        Text("동작 추가 → TokTokTok → ‘현재 시간 기록’을 넣고 저장해요")
            .font(.footnote)
            .foregroundStyle(Theme.secondaryText)
        Button {
            if let url = URL(string: "shortcuts://create-shortcut") { openURL(url) }
        } label: {
            Label("새 단축어 만들기", systemImage: "plus.square.on.square")
                .frame(minHeight: 44)
        }
        .foregroundStyle(.tint)
        .font(.body.weight(.medium))
        VStack(alignment: .leading, spacing: 8) {
            Text("TokTokTok 동작 미리 보기")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
            ShortcutsLink()
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var verification: some View {
        if let latest {
            let p = DayPresentation(timeZone: .current)
            let block = p.blocks(for: [latest])[0]
            VStack(alignment: .leading, spacing: 4) {
                Label("마지막 단축어 기록", systemImage: "checkmark")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(block.timeText)
                        .font(.title2.monospacedDigit())
                        .foregroundStyle(Theme.text)
                    Text(block.dateText)
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryText)
                }
                Text("시각이 그대로라면 2단계를 다시 확인해 주세요")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
            }
            .accessibilityElement(children: .combine)
        } else if checkedAt != nil {
            Text("최근 2주 동안 단축어 기록이 없어요")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
        } else {
            ProgressView()
        }
        Button {
            Task { await refresh() }
        } label: {
            Label("다시 확인", systemImage: "arrow.clockwise")
                .frame(minHeight: 44)
        }
        .foregroundStyle(.tint)
        .font(.body.weight(.medium))
    }

    private func refresh() async {
        let found: TimeRecord? = await Task.detached {
            try? RecordTimeService.live().latestRecord(source: .intent)
        }.value
        latest = found
        checkedAt = Date()
    }

    private func stepRow(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(n)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(Theme.mutedText)
                .frame(minWidth: 16, alignment: .leading)
                .accessibilityHidden(true)
            Text(text)
                .foregroundStyle(Theme.text)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(n)단계. \(text)")
    }
}
