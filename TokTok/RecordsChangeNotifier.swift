import Foundation

/// 같은 프로세스 안에서 Intent 저장 후 화면에 새로고침을 알린다.
/// Intent가 앱 프로세스 밖에서 실행되거나 앱이 종료된 상태면 전달되지 않으므로,
/// 화면은 활성화될 때마다 저장소를 다시 읽는다.
enum RecordsChangeNotifier {
    static let name = Notification.Name("TokTokRecordsChanged")

    static func post() {
        NotificationCenter.default.post(name: name, object: nil)
    }
}
