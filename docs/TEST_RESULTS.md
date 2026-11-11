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
| 하루 화면 다크·라이트 | `defaults write <번들 ID> toktok.appearance dark/light` 후 시뮬레이터 스크린숏(예시 기록 5건) | PASS (시각 확인, 시뮬레이터) |
| 색상 대비 라이트(계산값) | 본문/바탕 13.66, 본문/홈 12.56, 보조/바탕 6.53, 보조/홈 6.00, 흐린/바탕 5.17, 흐린/홈 4.75, 강조/바탕 5.13 | PASS (WCAG 계산. 렌더링 측정 NOT RUN) |
| 색상 대비 다크(계산값) | 본문/바탕 13.88, 본문/홈 14.83, 보조/바탕 6.70, 보조/홈 7.16, 흐린/바탕 4.86, 흐린/홈 5.19, 강조/바탕 8.81 | PASS (WCAG 계산) |
| 설정 ‘화면 모드’ 전환 UI, 설정·연결 안내 화면의 라이트 모드 | 컴파일만 확인 | NOT RUN |
| 버튼 누름(튀어나옴→파임), 큰 글씨, VoiceOver, 실기기 | | NOT RUN |

## R-010 unslop 다듬기·글꼴 교체 (feature/ui-redesign)

- 날짜: 2026-11-10 / 실행: Claude Opus 5.5(claude-opus-5-5), Xcode 26.5(17F42)
- 변경: 헤더 시작선 20 정렬, 카드 24·홈 12 모서리, 다크 그림자 강화, 라이트 눈금색 분리(`tick` #C98A1E), 기록 사이 구분선 제거, 설정·안내 화면 카드화, 글꼴 SF Pro Rounded(시각 300)
- 명령: `xcodebuild test`(iPhone 17 Pro 시뮬레이터, iOS 26.5) → TokTokTests 6 passed, 0 failed

| 항목 | 내용 | 판정 |
|---|---|---|
| 하루 화면 다크·라이트 | 시뮬레이터 스크린숏: 시작선 정렬, 다크 카드 윤곽, 얇은 둥근 숫자 | PASS (시각 확인, 시뮬레이터) |
| 대비 | 글자 토큰 값은 R-009와 같음(본문·보조·흐린·accent 모두 4.5:1 이상). `tick`은 글자가 아닌 눈금 | 변경 없음 |
| 설정·뒷면 탭 연결·개인정보 카드 화면 | 컴파일만 확인(시뮬레이터에서 탭 이동 불가) | NOT RUN |
| 큰 글씨, VoiceOver(카드 머리글 isHeader), 실기기 | | NOT RUN |

## R-011 헤더 구간·박스 날짜·기록 버튼·설정 글 줄이기 (feature/ui-redesign)

- 날짜: 2026-11-10 / 실행: Claude Opus 5.5(claude-opus-5-5), Xcode 26.5(17F42), Apple Swift 6.3.2
- 변경: 헤더 구간 문구를 하루 눈금 양끝 라벨로 이동, 박스 날짜 두 줄(일 + 월·요일), 기록 버튼 둥근 사각형(20), 설정·안내 문구 축약, 시간대 안내를 개인정보 화면으로 이동
- 명령: `cd TokTokCore && swift test` → 32 tests, 0 failures(`DayPresentationTests`에 dayText·monthWeekdayText 검증 추가) / `xcodebuild test`(iPhone 17 Pro 시뮬레이터, iOS 26.5) → 6 passed, 0 failed

| 항목 | 내용 | 판정 |
|---|---|---|
| 하루 화면 라이트·다크 | 시뮬레이터 스크린숏 | PASS (시각 확인, 시뮬레이터) |
| 설정·안내·개인정보 화면 문구 | 컴파일만 확인 | NOT RUN (화면 확인 안 함) |
| VoiceOver 제목+구간 낭독, 큰 글씨, 실기기 | | NOT RUN |

## R-012 기록 목록 한 판·날짜 첫 행만·위쪽 쌓기 (feature/day-list-panel)

- 날짜: 2026-11-10 / 실행: Claude Opus 5.5(claude-opus-5-5), Xcode 26.5(17F42), Apple Swift 6.3.2
- 기준: main 156cc35에서 분기
- 변경: 사용자 결정(HTML 시안 H). 기록 목록 전체를 파인 판 하나에 담고 최신 행만 튀어나옴, 시각과 날짜를 한 행에 묶음, 날짜는 같은 달력 날짜 묶음의 맨 위 행에만(`RecordBlock.showsDate`), 목록은 위쪽 정렬
- 명령: `cd TokTokCore && swift test` → 33 tests, 0 failures(`testShowsDateOnlyWhenCalendarDateChanges` 추가, 기존 예시에 showsDate 검증 추가) / `xcodebuild -project TokTok.xcodeproj -scheme TokTok -destination 'generic/platform=iOS' build` → BUILD SUCCEEDED

| 항목 | 내용 | 판정 |
|---|---|---|
| 날짜 첫 행 규칙·VoiceOver 날짜 포함 | TokTokCore 단위 테스트 | PASS |
| 앱 빌드 | generic iOS 빌드 | PASS (빌드만) |
| 앱 테스트(TokTokTests) | 디스크 여유 703MB로 시뮬레이터 빌드 생략, 실기기 테스트는 개인 기록 영향을 피해 미실행 | NOT RUN |
| 하루 화면 모양(판·최신 행·위쪽 정렬·자정 넘김 날짜) | HTML 시안으로만 확인, 앱 화면은 사용자 실기기 캡처 대기 | NOT RUN |
| 큰 글씨(AX)·VoiceOver·라이트 모드 실기기 | | NOT RUN |

## R-013 설정 메인 색·설정 문구 정리·README 재작성 (feature/settings-accent, feature/day-list-panel 기반)

- 날짜: 2026-11-10 / 실행: Claude Opus 5.5(claude-opus-5-5), Xcode 26.5(17F42), Apple Swift 6.3.2
- 변경: 설정 ‘메인 색’(호박·산호·세이지·하늘·라벤더, `toktok.accent`), 설정에서 ‘현재 설정’·‘지금 구간’ 예시·꼬리말 제거, README를 create-readme 스킬로 재작성
- 명령: `cd TokTokCore && swift test` → 33 tests, 0 failures / `xcodebuild test`(iPhone 17 Pro 시뮬레이터, iOS 26.5) → 6 passed, 0 failed

| 항목 | 내용 | 판정 |
|---|---|---|
| 메인 색 대비(계산값) | 5색 모두 라이트 tint/바탕 ≥ 5.13, 라이트 tick/홈 ≥ 3.05, 다크/바탕 ≥ 7.30 (DESIGN.md 메인 색 표) | PASS (WCAG 계산) |
| 하루 화면 메인 색 반영 | `defaults write … toktok.accent sky`(라이트)·`coral`(다크) 후 스크린숏, 눈금 색 변경 확인 | PASS (시각 확인, 시뮬레이터) |
| 설정 화면 메인 색 견본·선택 전환·문구 제거 | 컴파일만 확인(시뮬레이터에서 설정 화면 진입 불가) | NOT RUN |
| VoiceOver 선택됨 낭독, 큰 글씨, 실기기 | | NOT RUN |

## R-014 문서 docs/ 이동·목록 판 스크롤 모서리·설정 버튼 (feature/docs-and-polish)

- 날짜: 2026-11-10 / 실행: Claude Opus 5.5(claude-opus-5-5), Xcode 26.5(17F42)
- 변경: PRD·DESIGN·QUESTIONS·TEST_PLAN·TEST_RESULTS·TROUBLESHOOTING·SOURCES·HANDOFF를 docs/로 이동(CLAUDE.md·AGENTS.md·README.md는 맨 위 유지, 경로 갱신), 목록 판을 스크롤 밖에 고정하고 행을 둥근 판 모양으로 자름, 설정 ‘취소·적용’ 뉴모피즘 버튼, 화면 모드 뉴모피즘 분할 선택, ‘바로 적용돼요’ 제거
- 명령: `xcodebuild test`(iPhone 17 Pro 시뮬레이터, iOS 26.5) → 6 passed, 0 failed

| 항목 | 내용 | 판정 |
|---|---|---|
| 기록 많을 때 판 모양 | 예시 기록 17건 스크린숏: 판이 기록 버튼 위까지 차고 맨 아래 행이 판의 둥근 모서리로 잘림 | PASS (시각 확인, 시뮬레이터) |
| 중간 스크롤 시 위쪽 모서리 | 시뮬레이터에서 스크롤 조작 불가. 같은 clipShape가 위쪽에도 적용됨(코드 확인) | NOT RUN (조작 필요) |
| 설정 취소·적용·화면 모드 버튼 | 컴파일만 확인 | NOT RUN |

## R-015 기록 완료 소리·디자인 토스트 (feature/record-feedback)

- 날짜: 2026-11-10 / 실행: Claude Opus 5.5(claude-opus-5-5), Xcode 26.5(17F42)
- 변경: 저장 확인 후 ‘띵’ 한 번(`RecordSound`, System Sound Services), 단축어 결과를 글자 대신 `RecordToastView` 스니펫으로, 앱 안 성공 피드백을 위쪽 토스트(2초 자동 사라짐)로
- 명령: `cd TokTokCore && swift test` → 33 tests, 0 failures / `xcodebuild test`(iPhone 17 Pro 시뮬레이터, iOS 26.5) → 6 passed, 0 failed

| 항목 | 내용 | 판정 |
|---|---|---|
| 토스트 디자인 라이트·다크 | 임시 테스트에서 ImageRenderer로 그려 확인(임시 테스트는 커밋 안 함) | PASS (렌더링 확인) |
| 소리 파일 번들 포함 | 빌드된 앱에 record-ding.wav 포함 확인 | PASS |
| 무음 모드에서 소리 안 남 / 무음 아닐 때 한 번 | | NOT RUN (실기기 필요) |
| 뒷면 탭·단축어 실행 시 스니펫 표시·소리 | | NOT RUN (실기기 필요) |
| 앱 안 버튼 → 위쪽 토스트·2초 뒤 사라짐 | 시뮬레이터 조작 불가 | NOT RUN |

## R-016 기록 완료 소리 제거 (feature/remove-record-sound)

- 날짜: 2026-11-10 / 사용자 결정: 새벽에 울리면 안 되므로 소리 제거, 토스트만 잠깐 표시
- 변경: `RecordSound`·`record-ding.wav` 삭제, Intent·앱 안 기록에서 재생 호출 제거
- R-015의 소리 관련 NOT RUN 항목은 기능 제거로 해당 없음

## R-017 단축어 결과 토스트 제거 (feature/no-intent-toast)

- 날짜: 2026-11-10 / 사용자 결정: 뒷면 탭 실행 중 iOS 표시가 이미 보이므로 앱 결과 토스트 제거
- 변경: `RecordNowIntent`가 스니펫·대화 없이 `.result()`만 반환. 앱 안 기록 토스트는 유지

## R-019 오늘 기록 지우기·설정 상단 고정·다크 아이콘 고정 (feature/settings-reset)

- 번호 정정: PR #19·커밋 b15ee50에서는 R-013으로 적었으나 기존 R-013(메인 색)과 겹쳐 R-019로 바꿈

- 날짜: 2026-11-10 / 실행: Claude Opus 5.5(claude-opus-5-5), Xcode 26.5(17F42), Apple Swift 6.3.2
- 기준: main 516c618에서 분기
- 변경: Q06 사용자 결정. `FileRecordRepository.delete`(넘겨준 기록과 내용이 같은 파일만 삭제), `RecordTimeService.deleteRecords`, 설정 맨 아래 ‘오늘 기록 지우기’+확인 대화상자, 설정 ‘취소·설정·적용’ 줄을 스크롤 밖에 고정, 앱 아이콘 다크 한 장으로 고정
- 명령: `cd TokTokCore && swift test` → 35 tests, 0 failures(`testDeleteRemovesOnlyConfirmedRecords`, `testDeleteSkipsFileWhoseContentDiffers` 추가) / `xcodebuild -project TokTok.xcodeproj -scheme TokTok -destination 'generic/platform=iOS' build` → BUILD SUCCEEDED

| 항목 | 내용 | 판정 |
|---|---|---|
| 확인한 기록만 삭제, 이후 기록·읽지 못한 파일 보존, 내용 다른 같은 ID 미삭제 | TokTokCore 단위 테스트(실제 파일 저장소) | PASS |
| 앱 빌드 | generic iOS 빌드 | PASS (빌드만) |
| 설정 스크롤 시 상단 줄 고정, 삭제 대화상자·삭제 후 하루 화면 갱신, 아이콘 | 사용자 실기기 확인 대기 | NOT RUN |
| 앱 테스트(TokTokTests) | 디스크 여유 부족으로 미실행 | NOT RUN |


## R-018 뒷면 탭 연결 화면 레이아웃 (feature/backtap-guide-layout)

- 날짜: 2026-11-10 / 실행: Claude Opus 5.5(claude-opus-5-5), Xcode 26.5(17F42)
- 변경: 단계 카드 3개(번호 원·설명·버튼), 설정 경로 칩, 시험 결과를 3단계 카드 안 파인 홈에 표시, ‘알아 두세요’ 아이콘 목록
- 확인 방법: 임시로 앱 시작 화면을 연결 안내로 바꾼 빌드(커밋 안 함)로 시뮬레이터 스크린숏 라이트·다크
- 명령: `xcodebuild test`(iPhone 17 Pro 시뮬레이터, iOS 26.5) → 6 passed, 0 failed

| 항목 | 판정 |
|---|---|
| 화면 배치 라이트·다크 | PASS (시각 확인, 시뮬레이터) |
| ‘단축어 앱에서 만들기’·ShortcutsLink 이동, 실제 뒷면 탭 연결 후 체크 표시 | NOT RUN (실기기) |
| 관찰: `ShortcutsLink` 버튼 이름이 ‘TokTok 단축어’로 보임(시스템이 앱의 번들 이름을 사용하는 것으로 보임, 표시 이름은 TokTokTok) | 후속 확인 |

## R-020 뒷면 탭 연결 화면 다시 정리 (feature/guide-fix)

- 날짜: 2026-11-11 / 실행: Claude Opus 5.5(claude-opus-5-5), Xcode 26.5(17F42)
- 사용자 보고: 기기에서 레이아웃이 깨짐(기종·화면 미기록), ‘동작 미리 보기’ 버튼으로 단축어 앱의 자동 단축어를 지웠더니 버튼이 사라져 헷갈림
- 변경: `ShortcutsLink` 제거, 줄바꿈 칩(WrapLayout)·번호 옆 들여쓰기 제거 → 제목 줄 + 전체 폭 내용, 단축어 만들기 4단계 목록, 설정 경로 세로 목록, 버튼 전체 폭
- 확인: 임시로 시작 화면을 연결 안내로 바꾼 빌드(커밋 안 함). 시뮬레이터 iPhone 17 Pro(iOS 26.5) 라이트·다크, iPhone SE 3세대(iOS 17.5) 기본·접근성 L 글자 크기

| 항목 | 판정 |
|---|---|
| 두 기종·접근성 큰 글씨에서 잘림·겹침 없이 세로로만 늘어남 | PASS (시각 확인, 시뮬레이터) |
| 사용자 기기(iPhone 13 mini 추정)에서 깨짐 해소 | NOT RUN (사용자 확인 필요) |

## R-021 뒷면 탭 연결 2단계 번호 목록·세 번 탭 (feature/guide-triple-tap)

- 날짜: 2026-11-11 / 사용자 요청: 2단계도 1단계처럼 번호로, 안내 기준은 두 번이 아니라 세 번 탭
- 변경: 설정 경로 세로 목록 → 번호 목록 6줄, 안내 문구 ‘세 번 탭’·‘뒷면을 세 번 톡톡톡’

## R-022 설정 순서·행 여백·지우기 강조·지우기 확인 창 (feature/settings-polish)

- 날짜: 2026-11-11 / 실행: Claude Opus 5.5(claude-opus-5-5), Xcode 26.5(17F42), Apple Swift 6.3.2
- 기준: main f464910에서 분기
- 변경(사용자 요청): 메인 색을 화면 모드 위로, 행 목록 카드 `NeuSection(compact:)`(위아래 4·행 사이 0), ‘오늘 기록 지우기’ 메인 색 글자·꼬리말 삭제, 시스템 확인 대화상자를 앱 확인 창(`DeleteConfirmView`, `DialogButtonStyle`)으로 교체, 제목 ‘11월 10일 기록을 지울까요?’
- 명령: `xcodebuild -project TokTok.xcodeproj -scheme TokTok -destination 'generic/platform=iOS' build` → BUILD SUCCEEDED / `cd TokTokCore && swift test` → 아래 표

| 항목 | 내용 | 판정 |
|---|---|---|
| TokTokCore 회귀 | `swift test` 35 tests, 0 failures | PASS |
| 앱 빌드 | generic iOS 빌드 | PASS (빌드만) |
| 설정 순서·여백·강조 글씨·확인 창 모양·바깥 탭 취소·VoiceOver 모달 | 사용자 실기기 확인 대기 | NOT RUN |


## R-023 기종별 화면 점검: iPhone 18 Pro·Duo (feature/ax-accent-labels)

- 날짜: 2026-11-11 / 실행: Claude Opus 5.5(claude-opus-5-5), Xcode 26.5(17F42) / 사용자 요청: 현재 나온 iPhone 18 Pro와 Duo만, 시뮬레이터 새로 설치하지 않음
- iPhone 18 Pro: Apple 공식 사양 2622×1206 px(3x) = 402×874 pt로 iPhone 17 Pro와 같아 기존 iPhone 17 Pro 시뮬레이터(iOS 26.5)로 확인
- iPhone Duo: Xcode 26.5에 기기 종류가 없고, 공식 사양이 아직 없어(타사 자료: 안쪽 약 7.6인치, 바깥 약 5.4인치, 수치 불일치) 확인하지 못함
- 확인 방법: 임시로 시작 화면을 바꾼 빌드(커밋 안 함). 하루 화면·설정·뒷면 탭 연결·첫 실행 × 라이트·다크, 하루 화면·설정 × 접근성 L 글자

| 항목 | 판정 |
|---|---|
| 18 Pro 크기: 4개 화면 라이트·다크 | PASS (시각 확인) |
| 18 Pro 크기: 하루 화면 접근성 L | PASS |
| 18 Pro 크기: 설정 접근성 L, 메인 색 이름 두 줄로 꺾여 견본 높이 어긋남 | FAIL → 수정(위쪽 정렬, 이름 한 줄·축소) 후 PASS |
| iPhone Duo | NOT RUN (시뮬레이터·공식 사양 없음) |

## R-024 Codex 검증(병합 후)과 삭제 대상 고정·부분 미삭제 보고 수정 (fix/delete-target-freeze)

- 날짜: 2026-11-11 / 구현: Claude Opus 5.5(claude-opus-5-5) / 검증: Codex, `codex exec -m gpt-6-astra -s read-only`(codex-cli 0.167.0). Codex 보고서는 런타임 모델 ID를 스스로 확인하지 못했다고 적음
- 검증 범위: 156cc35..a42544b(PR #11·#14·#17·#19·#21·#24). Codex 판정 FAIL. Codex 쪽 `swift test`·시뮬레이터 빌드는 읽기 전용 샌드박스 쓰기 제한으로 실행 실패(NOT RUN)
- 지적과 조치:
  - P1 확인 창 삭제 대상 미고정 → `PendingDelete`로 창을 열 때 기록일 제목·기록 배열 고정, `DayViewModel.deleteRecords(_:)`가 그 배열만 삭제
  - P1 일부 대상 읽기 실패·내용 불일치를 오류 없이 종료 → `RecordDeleteResult`(deleted·alreadyMissing·unreadable·mismatched) 반환, 설정에 ‘N개를 지웠어요. M개는 확인하지 못해 남겨 뒀어요.’ 표시
  - P3 TEST_PLAN 상태 문구·삭제 검증 범위 → 상태 문구 갱신, T17~T19 추가(T18·T19는 미실행, T19는 알려진 위험)
  - 그 밖의 위험(스크롤 위치 보존, 확인 창 큰 글씨·VoiceOver)은 실기기 확인 대상으로 남김
- 명령(구현 측): `cd TokTokCore && swift test` → 36 tests, 0 failures(`testDeleteReportsUnreadableTargetAndKeepsIt` 추가, 기존 삭제 테스트를 결과 구조로 갱신). 2차 수정 후 38 tests, 0 failures, 건너뜀 없음 / `xcodebuild ... -destination 'generic/platform=iOS' build` → BUILD SUCCEEDED / `build-for-testing` → TEST BUILD SUCCEEDED

| 항목 | 판정 |
|---|---|
| T17 삭제 보존·부분 보고(TokTokCore) | PASS |
| T18 확인 창 대상 고정(앱 경로) | NOT RUN (코드 수정만, 실기기 확인 대기) |
| T19 같은 ID 재시도·삭제 경합 | NOT RUN (알려진 위험) |
| 수정 후 Codex 재검증(1차) | FAIL: 접근 불가를 ‘이미 없음’으로 분류(P1② 잔존), EOF 빈 줄. 아래 2차 수정 |

- 2차 수정(Codex 재검증 지적): `fileExists` 대신 직접 읽고, 파일 없음 오류(Cocoa NSFileReadNoSuchFileError·NSFileNoSuchFileError, POSIX ENOENT)만 `alreadyMissing`, 권한 거부 등 그 밖의 읽기 실패는 `unreadable`로 보존·보고. 테스트 `testDeleteCountsInaccessibleTargetAsUnreadable`(월 디렉터리 권한 제거), `testNoSuchFileClassification` 추가. EOF 빈 줄 제거
- Codex 재검증(2차, `codex exec -m gpt-6-astra -s workspace-write`, 추적 파일 수정 금지 지시) 대상 4ece5d5: **PASS(수정 재검증 범위)**. P1①·P1②·P3·EOF 지적 모두 해소, 새 지적 없음. Codex 실행 `swift test --disable-sandbox`(모듈 캐시 경로 지정) → 38 tests, 0 failures, 0 skipped. Codex 쪽 시뮬레이터 build-for-testing은 패키지 캐시 쓰기 제한으로 BLOCKED. 실기기·T18·T19는 NOT RUN. Codex 실행 후 `git status` 변경 없음

## R-025 기록 완료 진동 한 번 (feature/record-haptic)

- 날짜: 2026-11-11 / 실행: Claude Opus 5.5(claude-opus-5-5), Xcode 26.5(17F42)
- 사용자 결정: 소리는 빼고 기록할 때마다 기본 진동 한 번. 아이폰 기본 문자음(노트) 재생을 Mac에서 들려 드렸으나, Apple 소리 파일 저작권·비공개 소리 번호 문제를 듣고 소리 없이 진동만 선택
- 변경: `RecordHaptic.vibrate()`(`kSystemSoundID_Vibrate`)를 앱 안 기록 성공·`RecordNowIntent` 저장 성공 뒤에 호출

| 항목 | 판정 |
|---|---|
| 빌드·앱 테스트(커밋 5e4d614 기준) | PASS: `xcodebuild test -project TokTok.xcodeproj -scheme TokTok -destination 'platform=iOS Simulator,id=<iPhone 17 Pro, iOS 26.5>'` → 6 passed, 0 failed / `cd TokTokCore && swift test` → 38 tests, 0 failures |
| 앱 안 버튼 기록 시 진동 한 번 | NOT RUN (시뮬레이터는 진동 없음, 실기기 필요) |
| 뒷면 탭·단축어 기록 시 진동 한 번(앱이 화면에 없을 때) | NOT RUN (실기기 필요) |
| 기기 진동 설정 끔 → 진동 없음 | NOT RUN (실기기) |

- Codex 독립 검증(병합 전, `codex exec --sandbox read-only`, 모델 gpt-6-astra): 코드 결함 없음. 저장 성공 뒤에만 진동, 공개 API·iOS 17 호환, background mode 추가 없음 확인. P3 1건(R-025 실행 근거 누락)을 지적받아 위 표에 명령·결과를 보완. Codex 환경에서 빌드·테스트는 읽기 전용 제한으로 BLOCKED

## R-026 설정 ‘진동’ 토글 (feature/vibration-toggle)

- 날짜: 2026-11-11 / 실행: Claude Opus 5.5(claude-opus-5-5), Xcode 26.5(17F42)
- 사용자 요청: 기기 설정과 상관없이 울리게(→ iOS가 허용하지 않아 불가, 안내함), 앱 설정에 진동 켜기·끄기
- 변경: `RecordHaptic.isEnabled`(`toktok.vibration`, 기본 켜짐) 확인 후에만 진동, 설정에 ‘진동’ 섹션과 `NeuToggleStyle`
- 확인: 임시로 시작 화면을 설정으로 바꾼 빌드(커밋 안 함)로 iPhone 17 Pro 시뮬레이터 라이트·다크·꺼짐 상태 스크린숏

| 항목 | 판정 |
|---|---|
| 설정 화면 진동 스위치 켜짐·꺼짐 표시 | PASS (시각 확인, 시뮬레이터) |
| 끄면 앱 안·뒷면 탭 기록에서 진동 없음 / 켜면 한 번 | NOT RUN (실기기 필요) |
- 빌드·앱 테스트(커밋 7fa0b3e): `xcodebuild test`(iPhone 17 Pro 시뮬레이터, iOS 26.5) → 6 passed, 0 failed
- Codex 독립 검증(병합 전, read-only, gpt-6-astra): P1~P3 결함 없음. 토글 OFF 시 앱·Intent 진동 차단, 기본값 일치, 접근성(.isToggle iOS 17·44pt·값) 확인. Codex 환경의 빌드·테스트는 읽기 전용 제한으로 BLOCKED

## R-027 진동 꼬리말 안내 (feature/vibration-hint)

- 날짜: 2026-11-11 / 사용자 요청: ‘기록할 때 진동’ 아래에 진동이 울리지 않을 때 확인할 기기 설정 안내
- 확인: 설정 화면 스크린숏(임시 진입 빌드, 커밋 안 함), `xcodebuild test`(iPhone 17 Pro 시뮬레이터, iOS 26.5) → 6 passed, 0 failed
- 2차(같은 날, feature/vibration-hint-card): 사용자 요청으로 안내를 꼬리말에서 진동 카드 안으로 옮기고 경로·값 두 줄로 정리. 라이트·다크 스크린숏 확인, `xcodebuild test` → 6 passed, 0 failed
- 3차(같은 날, feature/toggle-color): 켜짐 스위치 홈을 메인 색 `tick`으로 불투명하게, 진동 카드 여백을 ‘뒷면 탭 연결’ 카드와 같은 compact(위아래 4·줄 44)로. 스크린숏 확인, `xcodebuild test` → 6 passed, 0 failed

## R-029 빈 상태·앱 시작 화면 (feature/empty-and-launch)

- 날짜: 2026-11-11 / 실행: Claude Opus 5.5(claude-opus-5-5), Xcode 26.5(17F42)
- 변경: 빈 상태를 기록 목록과 같은 파인 판 + 빈 시각 창으로, 시작 화면 배경을 앱 바탕색과 같게(`Config/Info.plist` UILaunchScreen.UIColorName, `LaunchBackground` 색). Xcode 26.5 빌드 설정에는 시작 화면 색 키가 없어(`CoreBuildSystem.xcspec` 확인, `INFOPLIST_KEY_UILaunchScreen_Generation`만 있음) Info.plist 조각을 씀
- 확인: 빌드된 앱 Info.plist에 `UILaunchScreen = { UIColorName = LaunchBackground }`, `CFBundleDisplayName = TokTokTok` 유지. iPhone 17 Pro 시뮬레이터 빈 상태 라이트·다크 스크린숏

| 항목 | 판정 |
|---|---|
| 빈 상태 화면 라이트·다크 | PASS (시각 확인, 시뮬레이터) |
| 시작 화면 색이 바탕색과 같은지(깜빡임) | NOT RUN (시작 순간 캡처 불가, 실기기 확인) |

## R-030 설정 ‘적용’ 버튼 정리 (feature/settings-save-inline)

- 날짜: 2026-11-11 / 사용자 요청: 하루 시작 시간만 ‘적용’을 눌러야 해서 헷갈림
- 변경: 상단 ‘취소·적용’ → ‘닫기’만. 하루 시작 시간을 바꾸면 카드 안에 ‘되돌리기’·‘HH:MM로 저장’, 저장 후 화면 유지·버튼 숨김·VoiceOver 안내. 저장 안 하고 닫으면 변경 버림

| 항목 | 판정 |
|---|---|
| 빌드·앱 테스트 | PASS: `xcodebuild test`(iPhone 17 Pro 시뮬레이터, iOS 26.5) → 6 passed, 0 failed |
| 시간 변경 시 카드 안 버튼 표시 | PASS (임시로 시간을 1시간 바꾼 채 여는 빌드로 스크린숏, 커밋 안 함) |
| 저장·되돌리기 동작, 닫기 시 변경 버림 | NOT RUN (시뮬레이터 조작 불가, 실기기 확인) |

## R-031 뒷면 탭 연결 완료 요약 (feature/guide-connected)

- 날짜: 2026-11-11 / 변경: 단축어 기록이 있으면 요약 카드 + 단계 접기(‘연결 방법 다시 보기’)
- 확인: 임시로 시작 화면을 연결 안내로 바꾼 빌드(커밋 안 함), 예시 단축어 기록이 있는 상태에서 iPhone 17 Pro 시뮬레이터 라이트·다크 스크린숏 — PASS(시각 확인)
- `xcodebuild test`(iPhone 17 Pro 시뮬레이터, iOS 26.5) → failedTests:0 passedTests:6 
- NOT RUN: ‘다시 보기’ 펼치기 조작(시뮬레이터 조작 불가), 실기기

## R-032 기록 왼쪽 스와이프 삭제 (feature/swipe-delete)

- 날짜: 2026-11-11 / 실행: Claude Opus 5.5(claude-opus-5-5), Xcode 26.5(17F42) / 사용자 결정(Q06 추가)
- 변경: `SwipeToDelete`(휴지통 열기·끝까지 밀어 삭제·한 행만 열림·VoiceOver 삭제 동작), `DayViewModel.deleteOne`(스냅샷의 그 기록만 `deleteRecords`로, 실패 시 오류)
- 명령: `xcodebuild test`(iPhone 17 Pro 시뮬레이터, iOS 26.5) → 7 passed, 0 failed(신규 `testDeleteOneRemovesOnlyThatRecord`)
- 확인: 임시로 둘째 행을 열어 둔 빌드(커밋 안 함)로 라이트·다크 스크린숏

| 항목 | 판정 |
|---|---|
| 한 개만 지우고 나머지 유지(단위 테스트) | PASS |
| 휴지통 열린 모양·행 잘림·최신 행 그림자 유지 | PASS (시각 확인, 시뮬레이터) |
| 실제 스와이프 조작·끝까지 밀기·세로 스크롤과 충돌 여부 | NOT RUN (시뮬레이터 조작 불가, 실기기) |
- Codex 독립 검증 1차(병합 전, read-only, gpt-6-astra): 보류. P2 대상 없음 시 무알림, P2 실패 음성 안내 없음, P3 Q06 정책 혼재, 세로로 시작한 드래그가 가로로 끝나면 삭제 분기 위험 → 모두 수정(대상 없음 알림·음성, 실패 음성, Q06 일괄/개별 분리, 드래그 시작 방향 고정)
- Codex 재검증(2차): 대상 없음·실패 음성·Q06·드래그 방향은 PASS, `alreadyMissing` 분기 화면 알림 누락 P2 1건 → 화면 알림 추가, 테스트 `testDeleteOneAlreadyMissingShowsNotice`
- Codex 재검증(3차): P2 해결 확인, 새 결함 없음 → 병합 가능. 앱 테스트 9 passed, 0 failed

## R-033 삭제 그라데이션·모달 빛 번짐·위 막대 버튼·개인정보 화면 (feature/polish-back-privacy)

- 날짜: 2026-11-11 / 실행: Claude Opus 5.5(claude-opus-5-5), Xcode 26.5(17F42)
- 변경: 스와이프 삭제 메인 색 그라데이션·‘놓으면 지워짐’ 휴지통, 오늘 기록 지우기 확인 창의 밝은 그림자 제거(`extruded(glow: false)`)·배경 40%, 닫기·뒤로 버튼 모서리 12(`HeaderButtonStyle`), 뒷면 탭 연결·개인정보 화면 위 막대(`neuNavigation`)와 가장자리 밀어 뒤로 가기 유지, 개인정보 화면 아이콘 행으로 재구성
- 확인: 임시 진입 빌드(커밋 안 함)로 iPhone 17 Pro 시뮬레이터 스크린숏 — 스와이프 열림(라이트), 확인 창(라이트·다크), 개인정보(라이트·다크), 뒷면 탭 연결(라이트), 설정(라이트)

| 항목 | 판정 |
|---|---|
| 화면 배치·색 | PASS (시각 확인, 시뮬레이터) |
| 끝까지 밀 때 휴지통 채움 전환, 가장자리 밀어 뒤로 가기 | NOT RUN (시뮬레이터 조작 불가, 실기기) |
- Codex 독립 검증 1차(병합 전, read-only): 보류. P2 개인정보 ‘이 iPhone 안에만’ 과장, P2 위 막대 제목 큰 글씨 잘림, P3 버튼 색 문서 불일치, 뒤로 제스처 전환 중 상태 미검사 → 문구 ‘이 iPhone에 저장해요’, 제목 2줄·접근성 크기에서 아래로, 문서 정정, `transitionCoordinator == nil` 조건 추가
