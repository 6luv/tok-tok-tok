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

    var body: some View {
        NavigationStack {
            List {
                Section {
                    BoundaryPicker(hour: $hour, minute: $minute)
                    if let original {
                        Text("현재 설정: \(DayPresentation.boundaryText(original))")
                            .foregroundStyle(Theme.secondaryText)
                    }
                    Text("바꾸면 지난 기록도 새 기준으로 다시 묶여 보여요. 기록된 원래 시각은 바뀌지 않아요.")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryText)
                    Text("기록은 지금 기기의 시간대로 표시돼요. 여행 등으로 시간대가 바뀌면 표시 시각과 기록일이 달라질 수 있어요. 기록 당시 시간대 정보는 그대로 보관해요.")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryText)
                    if let errorText {
                        Label(errorText, systemImage: "exclamationmark.triangle")
                    }
                } header: {
                    Text("하루 시작 시간")
                }

                Section {
                    NavigationLink("뒷면 탭 연결") { RecordingGuideView() }
                    NavigationLink("개인정보와 데이터") { PrivacyInfoView() }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
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
        .preferredColorScheme(.dark)
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
