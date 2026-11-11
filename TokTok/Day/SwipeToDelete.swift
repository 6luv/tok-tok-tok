import SwiftUI

/// 기록 행 오른쪽 스와이프 삭제(사용자 결정 2026-11-11, Q06. 같은 날 왼쪽 → 오른쪽으로 변경).
///
/// - 오른쪽으로 조금 밀면 왼쪽에 휴지통 버튼이 나오고 멈춘다. 휴지통을 누르면 지운다.
/// - 끝까지(`fullSwipe` 이상) 밀면 바로 지운다.
/// - 다시 왼쪽으로 밀거나 행을 누르면 닫힌다. 한 번에 한 행만 열린다(`openID`).
/// - 세로 스크롤을 막지 않도록 드래그 시작 방향이 가로일 때만 반응한다(시작 방향을 끝까지 유지).
/// - VoiceOver는 ‘삭제’ 동작으로 같은 일을 한다.
struct SwipeToDelete<Content: View>: View {
    let id: UUID
    @Binding var openID: UUID?
    let onDelete: () -> Void
    @ViewBuilder let content: Content

    @State private var drag: CGFloat = 0
    @Environment(\.tokTokAccent) private var accent
    /// 드래그 시작 때 정한 방향(가로면 true). 세로로 시작한 드래그는 끝까지 무시한다(Codex 검증).
    @State private var horizontal: Bool?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// 휴지통이 보이도록 열리는 거리
    private let reveal: CGFloat = 72
    /// 이만큼 밀면 바로 지운다
    private let fullSwipe: CGFloat = 180

    private var base: CGFloat { openID == id ? reveal : 0 }
    /// 오른쪽으로만 밀린다(0 이상)
    private var offset: CGFloat { max(0, base + drag) }
    /// 0(닫힘) → 1(놓으면 지워지는 거리)
    private var progress: CGFloat { min(1, offset / fullSwipe) }
    private var willDelete: Bool { offset >= fullSwipe }

    var body: some View {
        ZStack(alignment: .leading) {
            // 밀수록 왼쪽에서 메인 색 그라데이션이 짙어져 ‘지우는 중’임을 보여 준다(사용자 요청 2026-11-11).
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [accent.tick.opacity(0), accent.tick.opacity(0.15 + 0.6 * progress)],
                                     startPoint: .trailing, endPoint: .leading))
                .opacity(offset > 0 ? 1 : 0)
                .accessibilityHidden(true)
            Button(action: delete) {
                Image(systemName: willDelete ? "trash.fill" : "trash")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(willDelete ? AnyShapeStyle(Theme.onAccent) : AnyShapeStyle(.tint))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(willDelete ? accent.tick : .clear))
                    .extruded(Circle(), depth: 3)
                    .scaleEffect(willDelete ? 1.1 : 1)
                    .animation(reduceMotion ? nil : Theme.ease(0.15), value: willDelete)
            }
            .buttonStyle(.plain)
            .padding(.leading, 14)
            .opacity(Double(min(1, offset / reveal)))
            .allowsHitTesting(openID == id)
            .accessibilityHidden(true)

            content
                .offset(x: offset)
                .contentShape(Rectangle())
                .onTapGesture { if openID == id { close() } }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 24)
                        .onChanged { value in
                            if horizontal == nil {
                                // 확실히 가로로 민 경우만 반응(가로가 세로의 2배 이상). 사용자 요청 2026-11-11: 덜 예민하게
                                horizontal = abs(value.translation.width) > abs(value.translation.height) * 2
                            }
                            guard horizontal == true else { return }
                            if openID != id, openID != nil { openID = nil }
                            drag = damped(value.translation.width)
                        }
                        .onEnded { value in
                            defer { horizontal = nil }
                            guard horizontal == true else {
                                settle { drag = 0 }
                                return
                            }
                            let total = base + damped(value.translation.width)
                            if total >= fullSwipe {
                                delete()
                            } else if total > reveal / 2 {
                                settle { openID = id; drag = 0 }
                            } else {
                                settle { if openID == id { openID = nil }; drag = 0 }
                            }
                        }
                )
        }
        // 밀린 동안에만 행 모양(모서리 16)으로 잘라 판 밖으로 삐져나오지 않게 한다.
        // 가만히 있을 때는 넉넉히 덮어 최신 행의 튀어나온 그림자를 자르지 않는다.
        .mask {
            if offset > 0 {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
            } else {
                Rectangle().padding(-24)
            }
        }
        .accessibilityAction(named: "삭제", delete)
    }

    /// 손가락을 따라가는 양을 줄여(0.8배) 조금만 밀려도 크게 움직이지 않게 한다. 시작 거리(24)만큼은 빼고 따라간다.
    private func damped(_ width: CGFloat) -> CGFloat {
        let start: CGFloat = 24
        let moved = width > 0 ? max(0, width - start) : min(0, width + start)
        return moved * 0.8
    }

    private func settle(_ change: () -> Void) {
        withAnimation(reduceMotion ? nil : Theme.ease(0.25), change)
    }

    private func close() {
        settle { openID = nil; drag = 0 }
    }

    private func delete() {
        settle { openID = nil; drag = 0 }
        onDelete()
    }
}
