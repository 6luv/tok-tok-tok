import AppIntents
import Combine
import SwiftUI
import TokTokCore

/// 뒷면 탭 연결 도우미(R03).
///
/// 앱이 할 수 있는 것: 단축어 앱의 TokTok 페이지 열기(`ShortcutsLink`, iOS 16+),
/// 새 단축어 편집기 열기(`shortcuts://create-shortcut`, Apple 단축어 사용 설명서의 URL 스킴),
/// 연결 후 마지막 단축어 기록을 보여 줘 사용자가 직접 확인하게 하기.
/// 앱이 할 수 없는 것: 손쉬운 사용 > 뒷면 탭 설정 화면을 열거나 값을 바꾸기, 연결 여부 자동 확인.
/// 공개되지 않은 설정 URL은 사용하지 않는다.
struct RecordingGuideView: View {
    static let suggestedShortcutName = "TokTok 기록"

    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var latest: TimeRecord?
    @State private var checkedAt: Date?

    var body: some View {
        List {
            Section {
                Text("뒷면을 두 번 또는 세 번 톡톡 치면 지금 시각이 TokTok에 기록되도록 연결해요. iPhone 설정에서 직접 골라야 하는 부분이 있어서, 아래 순서대로 한 번만 따라 해 주세요.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            }
            .listRowBackground(Theme.raised)

            Section {
                stepRow(1, "단축어 앱에서 ‘TokTok 기록’ 단축어 만들기")
                Text("아래 버튼으로 새 단축어 편집기를 열고 ‘동작 추가’에서 TokTok → ‘현재 시간 기록’을 넣은 뒤, 이름을 ‘\(Self.suggestedShortcutName)’로 저장해요.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
                Button {
                    if let url = URL(string: "shortcuts://create-shortcut") { openURL(url) }
                } label: {
                    Label("새 단축어 만들기", systemImage: "plus.square.on.square")
                        .frame(minHeight: 44)
                }
                .foregroundStyle(Theme.accent)
                .font(.body.weight(.medium))
                VStack(alignment: .leading, spacing: 8) {
                    Text("TokTok 동작이 어디 있는지 먼저 보고 싶다면:")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryText)
                    ShortcutsLink()
                }
                .padding(.vertical, 4)
            } header: {
                Text("1. 단축어 만들기").textCase(nil)
            }
            .listRowBackground(Theme.raised)

            Section {
                stepRow(2, "설정 앱 → 손쉬운 사용 → 터치 → 뒷면 탭")
                stepRow(3, "‘두 번 탭’ 또는 ‘세 번 탭’ 선택")
                stepRow(4, "단축어 목록에서 ‘\(Self.suggestedShortcutName)’ 선택")
                Text("이 화면은 iPhone 설정 안에 있어서 TokTok이 대신 열거나 바꿀 수 없어요. 홈 화면의 설정 앱에서 직접 이동해 주세요. iOS 버전과 언어에 따라 메뉴 이름이 조금 다를 수 있어요.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
            } header: {
                Text("2. 뒷면 탭에 연결").textCase(nil)
            }
            .listRowBackground(Theme.raised)

            Section {
                stepRow(5, "뒷면을 톡톡 쳐 본 뒤 이 화면으로 돌아오기")
                verification
            } header: {
                Text("3. 연결 확인").textCase(nil)
            } footer: {
                Text("단축어·뒷면 탭·Siri로 실행한 기록은 앱에서 구분할 수 없어 모두 ‘단축어 기록’으로 보여요")
            }
            .listRowBackground(Theme.raised)

            Section {
                Text("기록 시각은 단축어가 TokTok을 실행한 순간이에요. 손가락으로 탭한 정확한 순간과 조금 차이가 날 수 있어요.")
                Text("단축어가 실행되면 화면 위에 짧은 알림이 보일 수 있어요. 이 알림은 iOS가 표시하며 TokTok이 끌 수 없어요.")
                Text("화면이 꺼져 있으면 iPhone이 뒷면 탭을 인식하지 않을 수 있어요. 실제 기기에서 화면이 꺼진 상태로는 기록되지 않는 것을 확인했어요. 이 동작은 iOS가 정하며 TokTok이 바꿀 수 없어요.")
                Text("화면을 끈 채로 기록하려면 Siri에게 “TokTok 기록”이라고 말해 보세요. 잠금 상태에서의 동작은 기기와 iOS 버전에 따라 다를 수 있으니, 중요한 기록은 하루 화면에서 저장됐는지 확인해 주세요.")
                Text("앱 안의 ‘현재 시간 기록’ 버튼은 연결 없이도 언제든 쓸 수 있어요.")
            } header: {
                Text("알아 두세요").textCase(nil)
            }
            .font(.subheadline)
            .foregroundStyle(Theme.secondaryText)
            .listRowBackground(Theme.raised)
        }
        .tokTokListStyle()
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
                Text("방금 뒷면을 탭했는데 이 시각이 바뀌지 않았다면 2단계 연결을 다시 확인해 주세요.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
            }
            .accessibilityElement(children: .combine)
        } else if checkedAt != nil {
            Text("최근 2주 동안 단축어로 저장된 기록이 아직 없어요")
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
        .foregroundStyle(Theme.accent)
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
                .font(.subheadline.monospaced())
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
