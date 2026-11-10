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

    var body: some View {
        NavigationStack {
            NeuPage {
                NeuSection {
                    BoundaryPicker(hour: $hour, minute: $minute)
                    if let original {
                        LabeledContent("현재 설정") {
                            Text(DayPresentation.boundaryText(original))
                                .monospacedDigit()
                                .foregroundStyle(Theme.secondaryText)
                        }
                        .foregroundStyle(Theme.text)
                    }
                    if let errorText {
                        Label(errorText, systemImage: "exclamationmark.triangle")
                            .font(.subheadline)
                            .foregroundStyle(Theme.text)
                    }
                } header: {
                    Text("하루 시작 시간")
                } footer: {
                    Text("바꿔도 기록된 시각은 그대로예요")
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
