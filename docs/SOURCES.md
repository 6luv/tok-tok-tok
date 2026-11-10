# 공식 근거와 확인 범위

확인일: 2026-10-31. Apple 공개 문서 기준이며, 링크 내용과 API availability는 구현·출시 시 사용 SDK에서 다시 확인한다. 문서 확인은 실제 기기 테스트의 대체가 아니다.

| ID | 공식 자료 | 적용 범위 |
|---|---|---|
| S01 | [Run shortcuts by tapping the back of your iPhone](https://support.apple.com/en-euro/guide/shortcuts/apd897693606/ios) | 두 번/세 번 탭에 단축어를 사용자가 연결하는 경로 |
| S02 | [openAppWhenRun](https://developer.apple.com/documentation/appintents/appintent/openappwhenrun) | 현재 문서의 deprecated 및 supportedModes 안내; 채택 SDK 호환성 확인 필요 |
| S03 | [IntentAuthenticationPolicy](https://developer.apple.com/documentation/appintents/intentauthenticationpolicy) | 잠금 실행 허용과 인증 요구 정책; 전체 실행 성공 보장은 아님 |
| S04 | [Protecting keys in alternative boot modes](https://support.apple.com/en-sg/guide/security/sece49ec4098/web) | 잠금 및 최초 잠금 해제 상태와 데이터 보호의 관계 |
| S05 | [Calendar.nextDate](https://developer.apple.com/documentation/foundation/calendar/nextdate(after:matching:matchingpolicy:repeatedtimepolicy:direction:)) | 존재하지 않거나 반복되는 지역 시각의 계산 정책 |
| S06 | [ModelContainer](https://developer.apple.com/documentation/swiftdata/modelcontainer) | 저장소 구성, 메모리 저장소·App Group·동기화 구성 구분 |
| S07 | [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) | 앱 내·메타데이터 개인정보처리방침, 제출 검토 |
| S08 | [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/) | 실제 수집·SDK 동작에 맞는 개인정보 공개 |
| S09 | [Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files) | 구현 시 필요한 manifest·API 신고 검토 시작점; 세부 적용 여부는 미검증 |

앱이 Back Tap을 직접 감지·설정하지 않는 설계, 무화면·햅틱을 보장하지 않는 범위 설정은 문서에 명시된 기능과 실제 환경 차이를 고려한 구현 방침이다. 특정 기기의 실행 성공 여부를 확인한 결과는 아니다.
