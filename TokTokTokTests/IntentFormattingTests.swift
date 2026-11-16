import XCTest
@testable import TokTokTok

final class IntentFormattingTests: XCTestCase {
    func testTimeTextIsHourMinuteSecond() {
        let text = IntentFormatting.timeText(Date())
        XCTAssertEqual(text.count, 8)
        XCTAssertEqual(Array(text)[2], ":")
        XCTAssertEqual(Array(text)[5], ":")
    }

    func testIntentErrorsSayRecordWasNotSaved() {
        for e in [RecordIntentError.boundaryNotConfigured, .saveFailed, .storageUnavailable] {
            XCTAssertTrue(String(localized: e.localizedStringResource).contains("기록되지 않았어요"))
        }
    }
}
