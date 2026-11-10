import SwiftUI
import TokTokCore

struct SettingsView: View {
    @ObservedObject var model: DayViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var hour = 0
    @State private var minute = 0
    @State private var original: DayBoundary?
    @State private var saving = false
    @State private var errorText: String?
    @AppStorage(AppAppearance.storageKey) private var appearance: AppAppearance = .dark
    @AppStorage(AppAccent.storageKey) private var accent: AppAccent = .amber

    var body: some View {
        NavigationStack {
            NeuPage {
                NeuSection {
                    BoundaryPicker(hour: $hour, minute: $minute, showsExample: false)
                    if let errorText {
                        Label(errorText, systemImage: "exclamationmark.triangle")
                            .font(.subheadline)
                            .foregroundStyle(Theme.text)
                    }
                } header: {
                    Text("하루 시작 시간")
                }

                NeuSection {
                    Picker("화면 모드", selection: $appearance) {
                        ForEach(AppAppearance.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("화면 모드")
                } footer: {
                    Text("바로 적용돼요")
                }

                NeuSection {
                    AccentPicker(selection: $accent)
                } header: {
                    Text("메인 색")
                }

                NeuSection {
                    NeuLinkRow(title: "뒷면 탭 연결") { RecordingGuideView() }
                    Theme.hairline.frame(height: 1)
                    NeuLinkRow(title: "개인정보와 데이터") { PrivacyInfoView() }
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saving ? "저장 중…" : "적용") { apply() }
                        .disabled(saving || !hasChanges)
                }
            }
            .onAppear(perform: loadCurrent)
        }
    }

    private var hasChanges: Bool {
        DayBoundary(hour: hour, minute: minute) != original
    }

    private func loadCurrent() {
        original = model.currentBoundary()
        if let original {
            hour = original.hour
            minute = original.minute
        }
    }

    private func apply() {
        guard let boundary = DayBoundary(hour: hour, minute: minute) else { return }
        saving = true
        errorText = nil
        Task {
            do {
                try await model.saveBoundary(boundary)
                dismiss()
            } catch {
                // 저장 실패 시 이전 설정이 유지된다.
                errorText = "저장하지 못했어요. 이전 설정이 그대로 유지돼요."
            }
            saving = false
        }
    }
}

/// 메인 색 후보: 튀어나온 원형 견본. 고른 색은 파인 원 안에 들어가 눌린 것처럼 보인다.
private struct AccentPicker: View {
    @Binding var selection: AppAccent

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppAccent.allCases) { option in
                let selected = option == selection
                Button {
                    selection = option
                } label: {
                    VStack(spacing: 8) {
                        Circle()
                            .fill(option.tick)
                            .frame(width: 24, height: 24)
                            .padding(10)
                            .modifier(SwatchDepth(selected: selected))
                        Text(option.title)
                            .font(.caption)
                            .foregroundStyle(selected ? Theme.text : Theme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.title)
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
    }
}

private struct SwatchDepth: ViewModifier {
    let selected: Bool

    func body(content: Content) -> some View {
        if selected {
            content.inset(Circle(), depth: 3)
        } else {
            content.extruded(Circle(), depth: 3)
        }
    }
}
