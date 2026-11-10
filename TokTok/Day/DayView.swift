import Combine
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
    @State private var showingBackTapGuide = false

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
        .onReceive(NotificationCenter.default.publisher(for: RecordsChangeNotifier.name).receive(on: RunLoop.main)) { _ in
            Task { await model.reload(markExternal: true) }
        }
        #if canImport(UIKit)
        // 시스템 시각·시간대 변경 시 현재 구간 재계산(T16)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification).receive(on: RunLoop.main)) { _ in
            Task { await model.reload() }
        }
        #endif
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange).receive(on: RunLoop.main)) { _ in
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
                .tint(Theme.accent)
        }
        .sheet(isPresented: $showingBackTapGuide) {
            NavigationStack {
                RecordingGuideView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("닫기") { showingBackTapGuide = false }
                        }
                    }
            }
            .preferredColorScheme(.dark)
            .tint(Theme.accent)
        }
    }

    // MARK: 하루 화면

    private var dayContent: some View {
        VStack(spacing: 0) {
            header
            Theme.hairline.frame(height: 1)
            recordList
            Theme.hairline.frame(height: 1)
            bottomBar
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Text(model.snapshot.map { model.presentation.headerTitle(for: $0.interval.day) } ?? "TokTok")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(Theme.text)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18, weight: .regular))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .foregroundStyle(Theme.secondaryText)
                .padding(.trailing, -12)
                .accessibilityLabel("설정")
            }
            if let snap = model.snapshot {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("구간")
                                .font(.caption)
                                .foregroundStyle(Theme.mutedText)
                            Text(model.presentation.rangeText(for: snap.interval))
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(Theme.secondaryText)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("기록 구간 \(model.presentation.rangeText(for: snap.interval))")
                        VStack(alignment: .leading, spacing: 2) {
                            Text("기록")
                                .font(.caption)
                                .foregroundStyle(Theme.mutedText)
                            Text("\(snap.records.count)개")
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(Theme.secondaryText)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("오늘 기록 \(snap.records.count)개")
                    }
                    Spacer(minLength: 0)
                    DayDialView(interval: snap.interval,
                                records: snap.records.sorted(by: TimeRecord.chronological).map(\.occurredAt),
                                timeZone: snap.timeZone)
                        .frame(width: 136, height: 136)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
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
                        if !model.blocks.isEmpty {
                            Theme.hairline.frame(height: 1)
                        }
                        ForEach(Array(model.blocks.enumerated()), id: \.element.id) { index, block in
                            if index > 0 { Theme.hairline.frame(height: 1).background(Theme.surface) }
                            RecordBlockView(block: block, isNewest: index == 0)
                                .id(block.id)
                                .transition(reduceMotion ? AnyTransition.identity : AnyTransition.opacity)
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
                        withAnimation(Theme.ease(0.35)) { proxy.scrollTo(target, anchor: .top) }
                    }
                    model.scrollTarget = nil
                }
                .overlay(alignment: .top) {
                    if model.unseenCount > 0 {
                        Button {
                            model.showNewest()
                        } label: {
                            Label("새 기록 \(model.unseenCount)개", systemImage: "arrow.up")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .padding(.top, 12)
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
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .padding(24)
        case .failed(let message):
            VStack(spacing: 8) {
                Text(message)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Theme.text)
                Text("기존 기록이 삭제된 것은 아니에요")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
                Button("다시 시도") { Task { await model.reload() } }
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.top, 8)
            }
            .multilineTextAlignment(.center)
            .padding(24)
        case .loaded where model.blocks.isEmpty:
            VStack(spacing: 16) {
                Text("기록한 순간이 여기에 쌓여요")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                Button {
                    showingBackTapGuide = true
                } label: {
                    Label("뒷면 탭으로 기록 연결하기", systemImage: "hand.tap")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .multilineTextAlignment(.center)
            .padding(24)
        default:
            EmptyView()
        }
        if let snap = model.snapshot, snap.unreadableCount > 0 {
            Text("읽지 못한 기록 파일 \(snap.unreadableCount)개가 있어요. 삭제하지 않고 보관 중이에요.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
        }
    }

    // MARK: 하단 기록 버튼

    private var bottomBar: some View {
        VStack(spacing: 12) {
            feedbackView
            RecordKeyButton(saving: model.inFlight > 0) {
                model.recordTapped()
            }
            .disabled(model.state == .loading && model.snapshot == nil)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Theme.background)
    }

    @ViewBuilder
    private var feedbackView: some View {
        switch model.feedback {
        case .saved(let text):
            Label(text, systemImage: "checkmark")
                .font(.footnote.monospacedDigit())
                .foregroundStyle(Theme.secondaryText)
        case .saveFailed(let pending):
            notice(icon: "exclamationmark.triangle",
                   title: "기록을 저장하지 못했어요",
                   detail: "\(model.presentation.timeText(pending.occurredAt))에 누른 기록이에요. 다시 시도하면 원래 시각으로 저장해요.") {
                Button("다시 시도") { model.retry(pending) }
                    .buttonStyle(SecondaryButtonStyle())
                Button("닫기") { model.dismissFeedback() }
                    .frame(minHeight: 44)
                    .padding(.horizontal, 12)
                    .foregroundStyle(Theme.secondaryText)
            }
        case .error(let message):
            notice(icon: "exclamationmark.triangle", title: message, detail: nil) {
                Button("닫기") { model.dismissFeedback() }
                    .buttonStyle(SecondaryButtonStyle())
            }
        case nil:
            EmptyView()
        }
    }

    /// 저장 실패·오류 알림 상자. 색이 아니라 아이콘과 문구로 상태를 전달한다.
    private func notice<Actions: View>(icon: String, title: String, detail: String?,
                                       @ViewBuilder actions: () -> Actions) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.text)
            if let detail {
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 8) { actions() }
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.boxRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.boxRadius, style: .continuous).strokeBorder(Theme.hairline))
    }
}

private struct TopOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
