import SwiftUI
import TokTokCore
#if canImport(UIKit)
import UIKit
#endif

struct DayView: View {
    @StateObject private var model = DayViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showingSettings = false

    private let topSentinelID = "toktok.top"

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            switch model.state {
            case .needsSetup:
                BoundarySetupView { boundary in
                    try await model.saveBoundary(boundary)
                }
            default:
                dayContent
            }
        }
        .task { await model.reload() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await model.reload(markExternal: true) } }
        }
        .onReceive(NotificationCenter.default.publisher(for: RecordsChangeNotifier.name)) { _ in
            Task { await model.reload(markExternal: true) }
        }
        #if canImport(UIKit)
        // 시스템 시각·시간대 변경 시 현재 구간 재계산(T16)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            Task { await model.reload() }
        }
        #endif
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in
            Task { await model.reload() }
        }
        // 설정한 경계에 도달하면 새 구간으로 재조회(자정이 아님)
        .task(id: model.snapshot?.interval.end) {
            guard let end = model.snapshot?.interval.end else { return }
            let wait = end.timeIntervalSinceNow
            if wait > 0 {
                try? await Task.sleep(nanoseconds: UInt64(min(wait, 86_400 * 2) * 1_000_000_000) + 500_000_000)
            }
            if !Task.isCancelled { await model.reload() }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(model: model)
        }
    }

    // MARK: 하루 화면

    private var dayContent: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(Theme.separator)
            recordList
            bottomBar
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                if let snap = model.snapshot {
                    Text(model.presentation.headerTitle(for: snap.interval.day))
                        .font(.title2.bold())
                        .foregroundStyle(Theme.text)
                        .accessibilityAddTraits(.isHeader)
                    Text(model.presentation.rangeText(for: snap.interval))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Theme.secondaryText)
                        .accessibilityLabel("기록 구간 \(model.presentation.rangeText(for: snap.interval))")
                } else {
                    Text("TokTok")
                        .font(.title2.bold())
                        .foregroundStyle(Theme.text)
                }
            }
            Spacer()
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.title3)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .foregroundStyle(Theme.text)
            .accessibilityLabel("설정")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var recordList: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        // 맨 위(최신 블록) 가시성 감지용
                        Color.clear.frame(height: 1).id(topSentinelID)
                            .background(GeometryReader { g in
                                Color.clear.preference(key: TopOffsetKey.self,
                                                       value: g.frame(in: .named("toktok.scroll")).minY)
                            })
                        Spacer(minLength: 0)
                        statusArea
                        ForEach(Array(model.blocks.enumerated()), id: \.element.id) { index, block in
                            if index > 0 { Theme.separator.frame(height: 1) }
                            RecordBlockView(block: block)
                                .id(block.id)
                                .transition(reduceMotion ? .identity : .opacity)
                        }
                    }
                    // 블록을 목록 영역 바닥에서부터 쌓는다
                    .frame(minHeight: geo.size.height, alignment: .bottom)
                }
                .coordinateSpace(name: "toktok.scroll")
                .onPreferenceChange(TopOffsetKey.self) { minY in
                    // 맨 위(최신 블록 쪽)가 화면에 보이는지
                    model.isViewingNewest = minY > -44
                    if model.isViewingNewest { model.clearUnseen() }
                }
                .onChange(of: model.scrollTarget) { _, target in
                    guard let target else { return }
                    if reduceMotion {
                        proxy.scrollTo(target, anchor: .top)
                    } else {
                        withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo(target, anchor: .top) }
                    }
                    model.scrollTarget = nil
                }
                .overlay(alignment: .top) {
                    if model.unseenCount > 0 {
                        Button {
                            model.showNewest()
                        } label: {
                            Text("새 기록 \(model.unseenCount)개")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 16)
                                .frame(minHeight: 44)
                                .background(Theme.accent, in: Capsule())
                                .foregroundStyle(Theme.onAccent)
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var statusArea: some View {
        switch model.state {
        case .loading:
            ProgressView("불러오는 중")
                .tint(Theme.secondaryText)
                .foregroundStyle(Theme.secondaryText)
                .padding(24)
        case .failed(let message):
            VStack(spacing: 8) {
                Text(message).foregroundStyle(Theme.text)
                Text("기존 기록이 삭제된 것은 아니에요.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
                Button("다시 시도") { Task { await model.reload() } }
                    .frame(minHeight: 44)
                    .foregroundStyle(Theme.accent)
            }
            .padding(24)
        case .loaded where model.blocks.isEmpty:
            Text("기록한 순간이 여기에 쌓여요")
                .foregroundStyle(Theme.secondaryText)
                .padding(24)
        default:
            EmptyView()
        }
        if let snap = model.snapshot, snap.unreadableCount > 0 {
            Text("읽지 못한 기록 파일 \(snap.unreadableCount)개가 있어요. 삭제하지 않고 보관 중이에요.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
        }
    }

    // MARK: 하단 기록 버튼

    private var bottomBar: some View {
        VStack(spacing: 8) {
            feedbackView
            Button {
                model.recordTapped()
            } label: {
                HStack(spacing: 8) {
                    if model.inFlight > 0 {
                        ProgressView().tint(Theme.onAccent)
                    }
                    Text(model.inFlight > 0 ? "저장 중…" : "현재 시간 기록")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(Theme.onAccent)
            }
            .accessibilityLabel("현재 시간 기록")
            .accessibilityHint("지금 이 순간의 시각을 저장합니다")
            .disabled(model.state == .loading && model.snapshot == nil)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Theme.background)
    }

    @ViewBuilder
    private var feedbackView: some View {
        switch model.feedback {
        case .saved(let text):
            Label(text, systemImage: "checkmark.circle")
                .font(.subheadline)
                .foregroundStyle(Theme.text)
        case .saveFailed(let pending):
            VStack(spacing: 6) {
                Label("기록을 저장하지 못했어요", systemImage: "exclamationmark.triangle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.text)
                Text("\(model.presentation.timeText(pending.occurredAt))에 누른 기록이에요. 다시 시도하면 원래 시각으로 저장해요.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                HStack {
                    Button("다시 시도") { model.retry(pending) }
                        .frame(minHeight: 44)
                    Button("닫기") { model.dismissFeedback() }
                        .frame(minHeight: 44)
                }
                .foregroundStyle(Theme.accent)
            }
        case .error(let message):
            VStack(spacing: 6) {
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.subheadline)
                    .foregroundStyle(Theme.text)
                    .multilineTextAlignment(.center)
                Button("닫기") { model.dismissFeedback() }
                    .frame(minHeight: 44)
                    .foregroundStyle(Theme.accent)
            }
        case nil:
            EmptyView()
        }
    }
}

private struct TopOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
