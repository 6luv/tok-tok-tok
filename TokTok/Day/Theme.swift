import SwiftUI

/// DESIGN.md 초안 토큰. 대비 측정 결과는 TEST_RESULTS.md R-004 참고.
enum Theme {
    static let background = Color(red: 0x0B / 255, green: 0x0B / 255, blue: 0x0D / 255)
    static let block = Color(red: 0x1C / 255, green: 0x1C / 255, blue: 0x1F / 255)
    static let separator = Color(red: 0x34 / 255, green: 0x34 / 255, blue: 0x38 / 255)
    static let text = Color(red: 0xF5 / 255, green: 0xF5 / 255, blue: 0xF7 / 255)
    static let secondaryText = Color(red: 0xB0 / 255, green: 0xB0 / 255, blue: 0xB8 / 255)
    static let accent = Color(red: 0xA7 / 255, green: 0xC7 / 255, blue: 0xFF / 255)
    /// 강조색 버튼 위 글자색
    static let onAccent = Color(red: 0x0B / 255, green: 0x0B / 255, blue: 0x0D / 255)
}
