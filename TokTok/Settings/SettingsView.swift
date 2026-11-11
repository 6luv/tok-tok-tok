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
    @State private var confirmingDelete = false
    @State private var deleting = false
    @State private var deleteMessage: String?
    @AppStorage(AppAppearance.storageKey) private var appearance: AppAppearance = .dark
    @AppStorage(AppAccent.storageKey) private var accent: AppAccent = .amber

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 취소 · 설정 · 적용은 스크롤해도 위에 고정한다(사용자 요청 2026-11-10)
                header
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    .background(Theme.background)
                    .zIndex(1)
                settingsList
            }
            .background(Theme.background)
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            // 시스템 막대 대신 화면 안의 뉴모피즘 버튼을 쓴다. 하위 화면(뒷면 탭 연결 등)은 시스템 뒤로 가기를 유지한다.
            .toolbar(.hidden, for: .navigationBar)
            .onAppear(perform: loadCurrent)
        }
        .overlay {
            if confirmingDelete {
                DeleteConfirmView(title: deleteTitle,
                                  confirmTitle: "\(dayRecordCount)개 지우기",
                                  onCancel: { setConfirming(false) },
                                  onConfirm: { setConfirming(false); deleteToday() })
                    .transition(.opacity)
            }
        }
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private func setConfirming(_ value: Bool) {
        if reduceMotion { confirmingDelete = value } else {
            withAnimation(Theme.ease(0.2)) { confirmingDelete = value }
        }
    }

    private var settingsList: some View {
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
                    AccentPicker(selection: $accent)
                } header: {
                    Text("메인 색")
                }

                NeuSection {
                    NeuSegmented(options: AppAppearance.allCases, selection: $appearance) { $0.title }
                } header: {
                    Text("화면 모드")
                }

                NeuSection(compact: true) {
                    NeuLinkRow(title: "뒷면 탭 연결") { RecordingGuideView() }
                    Theme.hairline.frame(height: 1)
                    NeuLinkRow(title: "개인정보와 데이터") { PrivacyInfoView() }
                }

                NeuSection(compact: true) {
                    Button {
                        setConfirming(true)
                    } label: {
                        HStack(spacing: 8) {
                            if deleting { ProgressView().tint(Theme.secondaryText) }
                            Label(deleting ? "지우는 중…" : "오늘 기록 지우기", systemImage: "trash")
                        }
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    // 강조 글씨: 메인 색(사용자 요청 2026-11-11). 지울 기록이 없으면 흐린색
                    .foregroundStyle(dayRecordCount > 0 ? AnyShapeStyle(.tint) : AnyShapeStyle(Theme.mutedText))
                    .font(.body.weight(.medium))
                    .disabled(dayRecordCount == 0 || deleting)
                    .accessibilityHint("\(dayTitle)의 기록 \(dayRecordCount)개를 지워요")
                    if let deleteMessage {
                        Label(deleteMessage, systemImage: "exclamationmark.triangle")
                            .font(.subheadline)
                            .foregroundStyle(Theme.text)
                            .padding(.vertical, 8)
                    }
                } header: {
                    Text("기록")
                }
            }
    }

    private var dayRecordCount: Int { model.snapshot?.records.count ?? 0 }

    /// "11월 10일" — 하루 시작 시간 기준 기록일
    private var dayTitle: String {
        guard let day = model.snapshot?.interval.day else { return "오늘" }
        return "\(day.month)월 \(day.day)일"
    }

    private var deleteTitle: String { "\(dayTitle) 기록을 지울까요?" }

    private func deleteToday() {
        deleting = true
        deleteMessage = nil
        Task {
            do {
                try await model.deleteCurrentDayRecords()
            } catch {
                // 일부만 지워졌을 수 있다. 남은 기록은 다시 불러온 목록에 그대로 보인다.
                deleteMessage = "기록을 지우지 못했어요. 남은 기록은 그대로예요."
            }
            deleting = false
        }
    }

    /// 취소 · 설정 · 적용. ‘적용’은 하루 시작 시간을 바꿨을 때만 켜지고 메인 색 글자로 보인다.
    private var header: some View {
        ZStack {
            Text("설정")
                .font(.headline)
                .foregroundStyle(Theme.text)
                .accessibilityAddTraits(.isHeader)
            HStack {
                Button("취소") { dismiss() }
                    .buttonStyle(SecondaryButtonStyle())
                Spacer()
                Button(saving ? "저장 중…" : "적용") { apply() }
                    .buttonStyle(SecondaryButtonStyle(emphasized: true))
                    .disabled(saving || !hasChanges)
            }
        }
        .padding(.top, 8)
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
        // 큰 글씨에서도 견본 원이 한 줄에 맞춰지도록 위쪽 정렬, 이름은 한 줄로 줄여 맞춘다.
        HStack(alignment: .top, spacing: 0) {
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
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .top)
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

/// ‘오늘 기록 지우기’ 확인 창(사용자 요청 2026-11-11, HTML 시안).
/// 시스템 회색 창 대신 앱과 같은 튀어나온 카드. 바깥을 누르면 취소된다. 빨간색은 쓰지 않는다.
private struct DeleteConfirmView: View {
    let title: String
    let confirmTitle: String
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)
                .accessibilityHidden(true)
            VStack(spacing: 0) {
                Image(systemName: "trash")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(.tint)
                    .frame(width: 56, height: 56)
                    .inset(Circle(), depth: 3)
                    .padding(.bottom, 16)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Theme.text)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text("지운 기록은 되돌릴 수 없어요")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                HStack(spacing: 12) {
                    Button("취소", action: onCancel)
                        .buttonStyle(DialogButtonStyle())
                    Button(confirmTitle, action: onConfirm)
                        .buttonStyle(DialogButtonStyle(emphasized: true))
                }
                .padding(.top, 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 20)
            .frame(maxWidth: 400)
            .extruded(RoundedRectangle(cornerRadius: 28, style: .continuous), depth: 7)
            .padding(.horizontal, 28)
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
            .accessibilityAction(.escape, onCancel)
        }
    }
}

