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

## R-002 로컬 저장·기록 서비스 (feature/local-storage)

- 실행 ID / 날짜: R-002 / 2026-10-31
- 실행 담당 / 모델: 구현 담당 Claude, `claude-opus-5-5` (검증 담당 아님)
- 대상: feature/local-storage (feature/day-boundary 기반 누적 브랜치)
- 도구: Swift 6.4.1-RELEASE, Linux x86_64. 임시 디렉터리의 실제 파일 저장소 사용(메모리 저장소 아님)
- 명령: `cd TokTokCore && swift test` (전체 28건 0 실패), `swift test --skip-build --filter StorageAndServiceTests` 10회 반복(매회 15건 0 실패)

| 테스트 | 내용 | 판정 |
|---|---|---|
| T01 | 시계 1회 읽기, 저장 지연 50ms에도 occurredAt 불변, 시간대·오프셋·source 저장 | PASS (Linux) |
| T07 | 23:00→00:00 경계 변경 후 UUID·시각·건수 동일, 표시 그룹 변경 | PASS (Linux) |
| T09 | 단일 프로세스 동시 100개 요청(app/intent 혼합) → 100건, ID 중복 0, 오류 0. 10회 반복 | PASS (Linux, 단일 프로세스) |
| T10 | 저장소 재생성 후 원본 필드 동일(소수 초 포함), 알 수 없는 source 값은 unknown | PASS (Linux). 이전 스키마 마이그레이션은 이전 버전이 없어 해당 없음 |
| T11 | 디렉터리 생성 실패 주입 → saveFailed(성공 응답 없음), 원인 제거 후 같은 ID·원래 시각으로 재시도 1건 | PASS (Linux) |
| T12 | 같은 ID 재저장 1건, 다른 ID 같은 시각 2건 | PASS (Linux) |
| T13 | 설정 쓰기 실패 주입 시 이전 값(04:30) 유지 | PASS (Linux) |
| T14 | UI 없이 `RecordTimeService.live` 생성, 미설정 시 boundaryNotConfigured·기록 0건, 설정 후 기록 | PASS (Linux, App Intent 런타임 아님) |
| T15 | 같은 시각 5건의 정렬이 반복 조회에서 동일 | PASS (Linux) |
| 기타 | 손상 파일은 삭제하지 않고 unreadableCount로 보고, 월 디렉터리 경계 조회 | PASS (Linux) |

- 미실행: T09의 앱·Intent 별도 프로세스 동시 쓰기, iOS 파일 보호(`completeUntilFirstUserAuthentication`) 하의 잠금 상태 쓰기, Apple 플랫폼 Foundation에서의 동일 테스트 — NOT RUN (Xcode 빌드·실기기 필요).
- 한계: 테스트를 root 권한으로 실행해 권한 거부(chmod) 방식의 실패 주입은 쓰지 않았다. 대신 디렉터리 자리에 파일을 둬 실패를 만들었다.

## R-003 Xcode 프로젝트·App Intent (feature/app-intent)

- 실행 ID / 날짜: R-003 / 2026-10-31
- 대상: feature/app-intent (feature/local-storage 기반 누적 브랜치)
- 실제 실행한 것:
  - `pbxproj` Python 파서(`pbxproj` 4.x)로 `TokTok.xcodeproj/project.pbxproj` 구문 파싱 성공, 타깃 `TokTok`·`TokTokTests` 확인, 끊긴 객체 참조 0건 — PASS (구문 검사만)
  - Apple 문서 확인: `openAppWhenRun` iOS 16.0–26.0(deprecated), `supportedModes` iOS 26.0+, `authenticationPolicy` iOS 16.0+ 기본 `.alwaysAllowed`
- 미실행:

| 항목 | 판정 | 이유 |
|---|---|---|
| Xcode 빌드(앱·Intent 컴파일, App Intents 메타데이터 추출) | NOT RUN | 이 세션에 Xcode 없음(TS-001) |
| TokTokTests (IntentFormattingTests) | NOT RUN | 동일 |
| T14 실제 App Intent 런타임(UI Scene 없이 실행) | NOT RUN | 실기기 필요. 서비스 단위는 R-002에서 PASS |
| 단축어 앱 액션 노출, 실기기 실행 매트릭스 전체 | NOT RUN | 실기기 필요 |

## R-004 하루 화면·설정·연결 안내 (feature/day-screen)

- 실행 ID / 날짜: R-004 / 2026-10-31
- 대상: feature/day-screen (feature/app-intent 기반 누적 브랜치)
- 명령: `cd TokTokCore && swift test` (Linux, Swift 6.4.1) → 31 tests, 0 failures

| 항목 | 내용 | 판정 |
|---|---|---|
| 표시 규칙 | DESIGN 예시: 헤더 “10월 31일 기록”, 구간 “10/31 23:00 – 11/01 23:00”, 블록 03:15:08(11월 1일) 위·23:18:42(10월 31일) 아래 | PASS (Linux) |
| VoiceOver 문구 | “11월 1일 오전 3시 15분 8초, 시간 기록” 생성 | PASS (Linux 문자열 생성만, 실제 VoiceOver 낭독 NOT RUN) |
| T15 | 같은 시각 기록의 표시 순서가 입력 순서와 무관 | PASS (Linux) |
| 색상 대비(토큰 계산값) | 본문/블록 15.61:1, 보조/블록 7.89:1, 본문/배경 18.06:1, 보조/배경 9.13:1, 버튼 글자/강조 11.48:1 — 모두 4.5:1 이상 | PASS (WCAG 공식으로 토큰 hex 계산. 실제 렌더링 측정은 NOT RUN) |
| 구분선/블록 대비 | 1.37:1. 텍스트가 아니라 장식 요소지만 블록 경계가 약하게 보일 수 있음 | 관찰(P3, TS-004) |
| TokTokTests (DayViewModelTests 4건, IntentFormattingTests 2건) | 실기기에서 실행할 앱 타깃 테스트 | NOT RUN (Xcode 필요) |
| UI·접근성 수동 점검(빈 상태, 1건, 50건, 큰 글씨 최대, VoiceOver, 모션 감소, 스크롤 유지·‘새 기록 N개’) | | NOT RUN (실기기 필요) |
| T16 경계 통과·백그라운드 복귀·시스템 시각 변경 갱신 | 코드: 구간 끝까지 대기 후 재조회, scenePhase active, significantTimeChange, 시간대 변경 알림 | NOT RUN (실기기 필요) |

## R-005 사용자 실기기 실행 보고 + 뒷면 탭 연결 도우미 (feature/back-tap-setup)

- 날짜: 2026-10-31
- 사용자 보고(Claude가 직접 관찰한 결과 아님): feature/day-screen을 사용자 iPhone에서 실행 확인. 기기 모델·iOS 버전·확인한 시나리오 범위는 아직 기록되지 않음.
  - 이에 따라 TS-005(앱 타깃 미컴파일)는 “사용자 Mac에서 빌드·실행됨(보고)”으로 갱신. TokTokTests 실행 결과는 여전히 NOT RUN.
- 원격 푸시: main, feature/branch-rules, feature/day-boundary, feature/local-storage, feature/app-intent, feature/day-screen를 origin에 푸시하고 `git rev-parse`로 로컬과 원격 커밋 일치 확인 — PASS
- 명령: `cd TokTokCore && swift test` (Linux, Swift 6.4.1) → 32 tests, 0 failures (신규 `testLatestIntentRecord` 포함)

| 항목 | 판정 |
|---|---|
| 최근 단축어 기록 조회(`latestRecord(source:)`): 없음 → 최신 intent 반환, app 기록 무시, 14일 밖 제외 | PASS (Linux) |
| 뒷면 탭 연결 도우미 화면(ShortcutsLink, 새 단축어 열기, 연결 확인 표시) | NOT RUN (Xcode 빌드·실기기 필요) |
| 사용자가 만든 단축어가 뒷면 탭 목록에 보이고 탭으로 기록되는지 | NOT RUN (실기기) |

## R-006 PR 병합 후 main 재검증

- 날짜: 2026-10-31 / 사용자 지시로 PR #1~#6을 순서대로 생성·병합(merge commit)
- 각 병합 직후 origin/main을 별도 worktree로 받아 `cd TokTokCore && swift test` 실행(Linux, Swift 6.4.1):

| 병합 | main 커밋 | 결과 |
|---|---|---|
| #1 feature/branch-rules | 2c2cc7f | TokTokCore 없음(문서만) |
| #2 feature/day-boundary | 11f0bca | 13건 PASS |
| #3 feature/local-storage | 67f8488 | 28건 PASS |
| #4 feature/app-intent | 2ae2887 | 28건 PASS |
| #5 feature/day-screen | 1ac1547 | 31건 PASS |
| #6 feature/back-tap-setup | fedbb12 | 32건 PASS |

- 병합 충돌: 없음(GitHub mergeable_state clean)
- 미실행: main 기준 Xcode 빌드·TokTokTests·실기기 확인, Codex 독립 검증

## R-007 뒷면 탭 실기기 결과 (사용자 보고)

- 날짜: 2026-10-31 / 실행: 사용자(Claude 직접 관찰 아님) / 기기: 기종·iOS 버전 미기록(사용 기종으로 iPhone 13 mini 언급)

| 상태 | 뒷면 탭 → 기록 | 판정 |
|---|---|---|
| 화면 켜짐(잠금 해제 여부 미기록) | 기록됨 | PASS (사용자 보고, 반복 횟수 미기록) |
| 화면 꺼짐 | 기록 안 됨 | FAIL (사용자 보고) → TS-007 |
| 화면 켜짐 + 잠금, 재부팅 후 최초 해제 전, 강제 종료, Siri 화면 꺼짐 | — | NOT RUN |

## R-008 화면 전면 개편 (feature/ui-redesign)

- 날짜: 2026-11-10 / 실행: Claude Opus 5.5(claude-opus-5-5), Xcode 26.5(17F42), Apple Swift 6.3.2, macOS 26.3.1
- 명령: `cd TokTokCore && swift test` → 32 tests, 0 failures / `xcodebuild test -project TokTok.xcodeproj -scheme TokTok -destination 'platform=iOS Simulator,id=<iPhone 17 Pro, iOS 26.5>'` → TokTokTests 6 passed, 0 failed

| 항목 | 내용 | 판정 |
|---|---|---|
| 빌드·앱 타깃 테스트 | 시뮬레이터 iPhone 17 Pro(iOS 26.5) | PASS (시뮬레이터) |
| 첫 실행 경계 설정 화면 | 시뮬레이터 스크린숏으로 배치·색 확인 | PASS (시각 확인, 시뮬레이터) |
| 하루 화면(기록 5건, 경계 04:00) | 예시 데이터를 시뮬레이터 앱 컨테이너에 넣고 스크린숏 확인: 하루 눈금·최신 블록 눈금·초 보조색·바닥 쌓기 | PASS (시각 확인, 시뮬레이터. 개인 기록 아님) |
| 색상 대비(토큰 계산값) | 본문/바탕 16.36, 본문/면 15.00, 보조/바탕 7.45, 보조/면 6.82, 흐린/바탕 5.22, 흐린/면 4.79, 강조/면 9.51, 버튼 글자/강조 9.98 | PASS (WCAG 공식 계산. 실제 렌더링 측정 NOT RUN) |
| 기록 박스 플립 패널(2차) | 문자판·스누즈 키 버튼 시도는 사용자 요청으로 되돌림(revert a753f8f). 이후 기록 박스만 플립 패널로 바꿔 TokTokTests 6 passed, 시뮬레이터 스크린숏 확인 | PASS (시뮬레이터) |
| 구분선/면 대비 | 1.23:1(이전 1.37:1). 면과 바탕의 단계 차이로 블록 경계를 보완 | 관찰(TS-004) |
| 설정·뒷면 탭 연결·개인정보 화면, 저장 실패 알림, ‘새 기록 N개’ | 컴파일만 확인 | NOT RUN (화면 확인 안 함) |
| 큰 글씨(AX) 세로 배치, VoiceOver, 모션 감소 | | NOT RUN |
| 실기기 | | NOT RUN |

## R-009 뉴모피즘 개편·다크/라이트 모드 (feature/ui-redesign)

- 날짜: 2026-11-10 / 실행: Claude Opus 5.5(claude-opus-5-5), Xcode 26.5(17F42), Apple Swift 6.3.2
- 명령: `cd TokTokCore && swift test` → 32 tests, 0 failures / `xcodebuild test`(iPhone 17 Pro 시뮬레이터, iOS 26.5) → TokTokTests 6 passed, 0 failed

| 항목 | 내용 | 판정 |
|---|---|---|
| 하루 화면 다크·라이트 | `defaults write com.example.TokTok toktok.appearance dark/light` 후 시뮬레이터 스크린숏(예시 기록 5건) | PASS (시각 확인, 시뮬레이터) |
| 색상 대비 라이트(계산값) | 본문/바탕 13.66, 본문/홈 12.56, 보조/바탕 6.53, 보조/홈 6.00, 흐린/바탕 5.17, 흐린/홈 4.75, 강조/바탕 5.13 | PASS (WCAG 계산. 렌더링 측정 NOT RUN) |
| 색상 대비 다크(계산값) | 본문/바탕 13.88, 본문/홈 14.83, 보조/바탕 6.70, 보조/홈 7.16, 흐린/바탕 4.86, 흐린/홈 5.19, 강조/바탕 8.81 | PASS (WCAG 계산) |
| 설정 ‘화면 모드’ 전환 UI, 설정·연결 안내 화면의 라이트 모드 | 컴파일만 확인 | NOT RUN |
| 버튼 누름(튀어나옴→파임), 큰 글씨, VoiceOver, 실기기 | | NOT RUN |
