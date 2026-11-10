import Foundation
import SwiftUI
import TokTokCore
#if canImport(UIKit)
import UIKit
#endif

/// 하루 화면 상태. 저장소 I/O는 메인 스레드 밖에서 실행한다.
@MainActor
final class DayViewModel: ObservableObject {
    enum LoadState: Equatable {
        case loading
        case needsSetup
        case loaded
        case failed(String)
    }

    enum Feedback: Equatable {
        case saved(Date)               // 기록된 시각. 화면 위쪽 토스트(RecordToastView)로 보인다
        case saveFailed(TimeRecord)    // 재시도 대상(원래 시각·작업 ID)
        case error(String)             // 재시도할 기록이 없는 실패(새 시각으로 몰래 저장하지 않음)
    }

    @Published private(set) var state: LoadState = .loading
    @Published private(set) var snapshot: DaySnapshot?
    @Published private(set) var blocks: [RecordBlock] = []
    @Published private(set) var inFlight = 0
    @Published private(set) var feedback: Feedback?
    /// 외부(Intent) 기록이 들어왔는데 사용자가 최신 위치를 보고 있지 않을 때의 개수.
    @Published private(set) var unseenCount = 0
    /// 앱 내 버튼으로 기록해 새 블록으로 이동해야 할 ID.
    @Published var scrollTarget: UUID?

    /// 화면 맨 위(최신 블록)가 보이는지. View가 갱신한다.
    var isViewingNewest = true

    private let serviceResult: Result<RecordTimeService, Error>
    private var feedbackToken = 0

    init(serviceFactory: () throws -> RecordTimeService = { try RecordTimeService.live() }) {
        serviceResult = Result { try serviceFactory() }
    }

    var service: RecordTimeService? { try? serviceResult.get() }

    var presentation: DayPresentation {
        DayPresentation(timeZone: snapshot?.timeZone ?? .current)
    }

    // MARK: 조회

    /// 현재 기록일을 다시 읽는다. 빈 데이터로 단정하기 전에 로딩 상태를 유지한다.
    func reload(markExternal: Bool = false) async {
        guard let service else {
            state = .failed("저장소를 열지 못했어요.")
            return
        }
        if snapshot == nil, state != .needsSetup { state = .loading }
        let result: Result<DaySnapshot, Error> = await Task.detached { Result { try service.loadDay() } }.value
        switch result {
        case .success(let snap):
            let oldIDs = Set(blocks.map(\.id))
            let newBlocks = DayPresentation(timeZone: snap.timeZone).blocks(for: snap.records)
            let sameDay = snapshot?.interval == snap.interval
            snapshot = snap
            blocks = newBlocks
            state = .loaded
            if markExternal, sameDay, !isViewingNewest {
                unseenCount += newBlocks.filter { !oldIDs.contains($0.id) }.count
            } else if !sameDay {
                unseenCount = 0
            }
        case .failure(RecordError.boundaryNotConfigured):
            snapshot = nil
            blocks = []
            state = .needsSetup
        case .failure:
            // 기존 표시를 지우지 않는다. 기록이 삭제된 것이 아니다.
            state = .failed("기록을 불러오지 못했어요.")
        }
    }

    func clearUnseen() {
        if unseenCount != 0 { unseenCount = 0 }
    }

    func showNewest() {
        unseenCount = 0
        scrollTarget = blocks.first?.id
    }

    // MARK: 기록

    /// 앱 내 기록 버튼(R01). 각 탭은 독립 요청이다.
    func recordTapped() {
        guard let service else {
            state = .failed("저장소를 열지 못했어요.")
            return
        }
        inFlight += 1
        Task {
            let result: Result<TimeRecord, Error> = await Task.detached { Result { try service.recordNow(source: .app) } }.value
            await self.finish(result)
        }
    }

    func retry(_ pending: TimeRecord) {
        guard let service else { return }
        inFlight += 1
        Task {
            let result: Result<TimeRecord, Error> = await Task.detached { Result { try service.retry(pending) } }.value
            await self.finish(result)
        }
    }

    private func finish(_ result: Result<TimeRecord, Error>) async {
        inFlight -= 1
        switch result {
        case .success(let record):
            await reload()
            scrollTarget = record.id
            unseenCount = 0
            let text = "\(presentation.timeText(record.occurredAt)) 기록됨"
            showFeedback(.saved(record.occurredAt), autoHide: true)
            announce(text)
        case .failure(RecordError.saveFailed(let pending)):
            showFeedback(.saveFailed(pending), autoHide: false)
            announce("기록을 저장하지 못했어요")
        case .failure(RecordError.boundaryNotConfigured):
            state = .needsSetup
        case .failure:
            showFeedback(.error("설정을 읽지 못해 기록하지 못했어요. 이번 탭은 기록되지 않았어요."), autoHide: false)
        }
    }

    func dismissFeedback() { feedback = nil }

    private func announce(_ text: String) {
        #if canImport(UIKit)
        UIAccessibility.post(notification: .announcement, argument: text)
        #endif
    }

    private func showFeedback(_ f: Feedback, autoHide: Bool) {
        feedbackToken += 1
        let token = feedbackToken
        feedback = f
        guard autoHide else { return }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if self.feedbackToken == token { self.feedback = nil }
        }
    }

    // MARK: 설정

    /// 경계 저장. 실패하면 이전 값이 유지되고 오류를 던진다.
    func saveBoundary(_ boundary: DayBoundary) async throws {
        guard let service else { throw SettingsError.saveFailed("저장소 없음") }
        let result: Result<AppSettings, Error> = await Task.detached { Result { try service.settings.setDayBoundary(boundary) } }.value
        _ = try result.get()
        await reload()
    }

    /// 지금 화면의 기록일 기록을 지운다. 사용자가 확인한 스냅샷의 기록만 대상이다.
    @discardableResult
    func deleteCurrentDayRecords() async throws -> Int {
        guard let service, let records = snapshot?.records, !records.isEmpty else { return 0 }
        let result: Result<Int, Error> = await Task.detached { Result { try service.deleteRecords(records) } }.value
        defer { Task { await reload() } }
        return try result.get()
    }

    func currentBoundary() -> DayBoundary? {
        (try? service?.settings.load())?.boundary
    }
}
