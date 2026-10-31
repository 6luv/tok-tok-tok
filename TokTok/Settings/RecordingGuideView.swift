import SwiftUI

/// 기록 방법 안내(R03). 앱은 뒷면 탭 설정을 직접 바꾸거나 연결 여부를 확인하지 않는다.
struct RecordingGuideView: View {
    var body: some View {
        List {
            Section("앱에서") {
                Text("하루 화면 아래의 ‘현재 시간 기록’ 버튼을 누르면 그 순간의 시각이 저장돼요.")
            }

            Section("단축어") {
                Text("단축어 앱에서 ‘TokTok’을 찾으면 ‘현재 시간 기록’ 동작이 있어요. 입력할 값 없이 바로 실행돼요.")
            }

            Section {
                step(1, "설정 앱을 열어요.")
                step(2, "손쉬운 사용 → 터치 → 뒷면 탭으로 이동해요.")
                step(3, "‘두 번 탭’ 또는 ‘세 번 탭’을 골라요.")
                step(4, "단축어 목록에서 ‘현재 시간 기록’을 선택해요.")
                Text("목록에 보이지 않으면 단축어 앱에서 새 단축어를 만들고 ‘TokTok’ → ‘현재 시간 기록’ 동작을 추가한 뒤, 그 단축어를 4단계에서 선택해 주세요.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
            } header: {
                Text("뒷면 탭 연결")
            } footer: {
                Text("iOS 버전과 언어에 따라 메뉴 이름이 조금 다를 수 있어요. TokTok은 이 설정을 대신 바꾸거나 연결됐는지 확인할 수 없어요. 연결한 뒤 한 번 탭해 보고 하루 화면에 기록이 생겼는지 확인해 주세요.")
            }

            Section("알아 두세요") {
                Text("기록 시각은 단축어가 TokTok을 실행한 순간이에요. 손가락으로 탭한 정확한 순간과 조금 차이가 날 수 있어요.")
                Text("잠금 상태나 화면이 꺼진 상태에서의 동작은 기기와 iOS 버전에 따라 다를 수 있으며 아직 확인되지 않았어요. 중요한 기록은 하루 화면에서 저장됐는지 확인해 주세요.")
                Text("처음 하루 시작 시간을 정하기 전에는 단축어로 기록할 수 없어요.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("기록 방법")
    }

    private func step(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(n)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(text)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(n)단계. \(text)")
    }
}
