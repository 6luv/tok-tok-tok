import SwiftUI

/// 기록 행 왼쪽 스와이프 삭제(사용자 결정 2026-11-11, Q06).
///
/// - 조금 밀면 오른쪽에 휴지통 버튼이 나오고 멈춘다. 휴지통을 누르면 지운다.
/// - 끝까지(`fullSwipe` 이상) 밀면 바로 지운다.
/// - 다시 오른쪽으로 밀거나 행을 누르면 닫힌다. 한 번에 한 행만 열린다(`openID`).
/// - 세로 스크롤을 막지 않도록 가로 움직임이 더 클 때만 반응한다.
/// - VoiceOver는 ‘삭제’ 동작으로 같은 일을 한다.
struct SwipeToDelete<Content: View>: View {
    let id: UUID
    @Binding var openID: UUID?
    let onDelete: () -> Void
    @ViewBuilder let content: Content

    @State private var drag: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// 휴지통이 보이도록 열리는 거리
    private let reveal: CGFloat = 72
    /// 이만큼 밀면 바로 지운다
    private let fullSwipe: CGFloat = 180

    private var base: CGFloat { openID == id ? -reveal : 0 }
    private var offset: CGFloat { min(0, base + drag) }

    var body: some View {
        ZStack(alignment: .trailing) {
            Button(action: delete) {
                Image(systemName: "trash")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.tint)
                    .frame(width: 44, height: 44)
                    .extruded(Circle(), depth: 3)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 14)
            .opacity(Double(min(1, -offset / reveal)))
            .allowsHitTesting(openID == id)
            .accessibilityHidden(true)

            content
                .offset(x: offset)
                .contentShape(Rectangle())
                .onTapGesture { if openID == id { close() } }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 16)
                        .onChanged { value in
                            guard abs(value.translation.width) > abs(value.translation.height) else { return }
                            if openID != id, openID != nil { openID = nil }
                            drag = value.translation.width
                        }
                        .onEnded { value in
                            guard abs(value.translation.width) > abs(value.translation.height) else {
                                settle { drag = 0 }
                                return
                            }
                            let total = base + value.translation.width
                            if total <= -fullSwipe {
                                delete()
                            } else if total < -reveal / 2 {
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
            if offset < 0 {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
            } else {
                Rectangle().padding(-24)
            }
        }
        .accessibilityAction(named: "삭제", delete)
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
