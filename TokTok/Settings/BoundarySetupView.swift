import SwiftUI
import TokTokCore

/// 첫 실행 경계 설정(Q01 잠정: 선택·확인 필수, 제품 기본값 없음).
/// 선택기의 처음 위치는 미리보기일 뿐이며 '이 시간으로 시작'을 눌러야 저장된다.
struct BoundarySetupView: View {
    let onConfirm: (DayBoundary) async throws -> Void

    @State private var hour = Calendar.current.component(.hour, from: Date())
    @State private var minute = 0
    @State private var saving = false
    @State private var errorText: String?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("하루가 시작되는 시간을 정해 주세요")
                            .font(.title2.weight(.medium).width(.expanded))
                            .foregroundStyle(Theme.text)
                            .accessibilityAddTraits(.isHeader)
                        Text("TokTok은 이 시간을 기준으로 하루치 기록을 묶어 보여줘요. 예를 들어 늦게 자는 편이라면 새벽 기록이 전날에 함께 보이도록 정할 수 있어요. 나중에 설정에서 바꿀 수 있어요.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        BoundaryPicker(hour: $hour, minute: $minute)
                    }
                    .padding(20)
                    .extruded(RoundedRectangle(cornerRadius: Theme.boxRadius + 4, style: .continuous))
                    if let errorText {
                        Label(errorText, systemImage: "exclamationmark.triangle")
                            .font(.subheadline)
                            .foregroundStyle(Theme.text)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 32)
                .padding(.bottom, 24)
            }
            VStack(spacing: 12) {
                Text("값을 고른 뒤 아래 버튼을 눌러야 저장돼요")
                    .font(.footnote)
                    .foregroundStyle(Theme.mutedText)
                Button {
                    confirm()
                } label: {
                    Text(saving ? "저장 중…" : "이 시간으로 시작 · \(String(format: "%02d:%02d", hour, minute))")
                        .monospacedDigit()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(saving)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .background(Theme.background)
    }

    private func confirm() {
        guard let boundary = DayBoundary(hour: hour, minute: minute) else { return }
        saving = true
        errorText = nil
        Task {
            do {
                try await onConfirm(boundary)
            } catch {
                errorText = "설정을 저장하지 못했어요. 다시 시도해 주세요."
            }
            saving = false
        }
    }
}
