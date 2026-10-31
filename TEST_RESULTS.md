# 검증 결과 기록

현재 상태: 부분 실행. 플랫폼 독립 로직(TokTokCore)은 Linux Swift로 자동 테스트를 실행했다. iOS 앱 빌드·실기기 검증은 아래 각 항목에 표시한 대로 미실행이다. 시뮬레이터는 사용자 결정(2026-10-31, 저장공간 부족)으로 사용하지 않고 실기기로 검증한다.

## 실행 기록 템플릿

- 실행 ID / 날짜:
- 검증 담당 / 실제 모델 ID:
- 대상 커밋·변경 상태:
- Xcode / Swift / SDK / 최소 OS:
- 기기·OS·시뮬레이터 구분:
- 요구사항 ID / 테스트 ID:
- 실제 실행 명령 또는 수동 단계:
- 기대 결과 / 실제 결과:
- 판정: PASS / FAIL / BLOCKED / NOT RUN
- 증거 경로(개인 기록 제거):
- 연결 이슈 / 수정 커밋 / 재검증 결과:

## 요약

| 범주 | 상태 | 근거 |
|---|---|---|
| 빌드·자동 테스트 | NOT RUN | 앱 프로젝트 미생성 |
| UI·접근성 | NOT RUN | 앱 프로젝트 미생성 |
| 실기기·잠금·Back Tap | NOT RUN | 구현 및 실기기 실행 전 |
| App Store 제출 준비 | NOT RUN | 배포 정보 미확정 |

결과를 추가할 때 이전 실패를 덮어쓰지 않는다. 민감한 시간 기록, 기기 식별자, 서명 비밀은 증거에 포함하지 않는다.

## R-001 하루 경계 계산 (feature/day-boundary)

- 실행 ID / 날짜: R-001 / 2026-10-31
- 실행 담당 / 모델: 구현 담당 Claude, 세션 구성 모델 ID `claude-opus-5-5` (검증 담당 아님)
- 대상: feature/day-boundary 브랜치, TokTokCore 패키지
- 도구: Swift 6.4.1-RELEASE, x86_64-unknown-linux-gnu (Ubuntu 24.04 클라우드 작업 공간). Xcode/iOS SDK 아님
- 명령: `cd TokTokCore && swift test`
- 결과: 13 tests, 0 failures
- 판정:

| 테스트 | 내용 | 판정 |
|---|---|---|
| T02 | 00:00·06:00·23:00·13:37 직전/정확히/직후 | PASS (Linux) |
| T03 | 23:00 설정 10/31 22:59:59 → 10/30, 23:00 → 10/31, 11/01 03:15 블록 날짜 11/01 | PASS (Linux) |
| T04 | 월말·연말·2028-02-29·2100-02-28, 1440개 모든 분 값 구간 왕복 (Seoul, New York) | PASS (Linux) |
| T05 | New York 2026-03-08 02:30 → 03:00 EDT(07:00Z), 2026-11-01 01:30 → 첫 발생(05:30Z) | PASS (Linux) |
| T06 | DST 전후 구간 연속성, 23h/25h 기록일, 15분 간격 소속 유일성 | PASS (Linux) |
| T08 | 같은 순간을 Seoul/LA 시간대로 조회 시 기록일 차이(잠정 Q03) | PASS (Linux, 계산기 단위) |
| S05 교차 | Foundation `Calendar.nextDate(.nextTime, .first)`와 96개 분 값 × 3일 일치 | PASS (Linux Foundation) |

- 한계: Linux의 swift-foundation/ICU 결과다. Apple 플랫폼 Foundation에서의 동일 결과는 Xcode 테스트 실행 전까지 NOT RUN. 계산기는 `TimeZone.secondsFromGMT(for:)`만 사용해 플랫폼 차이를 줄였다.
