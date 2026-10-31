# 인계 — TokTok MVP 1차 구현 (2026-10-31)

구현 담당: Claude (세션 구성 모델 ID `claude-opus-5-5`). Codex 독립 검증: **미실행**(이 세션에서 실행 불가). 2026-10-31 사용자 지시로 브랜치 규칙을 ‘PR 생성 후 main 병합’으로 바꾸고, 아래 기능을 모두 PR로 main에 병합했다. 병합 후 Codex 검증은 별도로 요청할 수 있다.

## 환경과 제약

- 사용자 Mac에 연결된 명령 환경은 Linux VM이라 Xcode를 실행할 수 없었다(TS-001). iOS 앱 타깃은 **컴파일하지 않았다**(TS-005).
- 플랫폼 독립 로직(TokTokCore)은 Linux Swift 6.4.1로 `swift test` 실행: 31건 통과.
- 시뮬레이터는 사용하지 않는다(사용자 결정). 실기기 검증은 아래 절차로 사용자가 진행한다.
- 원격(origin)은 인증 정보가 없어 fetch하지 못했다. 브랜치 비교는 로컬 기준. 푸시·PR 없음.

## 브랜치 (누적 구조)

```
main ─┬─ feature/branch-rules
      └─ feature/day-boundary ─ feature/local-storage ─ feature/app-intent ─ feature/day-screen ─ feature/back-tap-setup
```

병합 순서: branch-rules(#1) → day-boundary(#2) → local-storage(#3) → app-intent(#4) → day-screen(#5) → back-tap-setup(#6). 모두 merge commit으로 병합했고, 각 병합 직후 main에서 `swift test`를 다시 실행했다(13 → 28 → 28 → 31 → 32건, 실패 0).

원격: github.com/6luv/tok-tok. 브랜치는 삭제하지 않았다.

| 브랜치 | 기준 | 변경 내용 | 요구사항·테스트 | 테스트 결과 | 남은 문제 | Codex | main 병합 |
|---|---|---|---|---|---|---|---|
| feature/branch-rules | main | CLAUDE.md·AGENTS.md에 브랜치 규칙 | — | 해당 없음(문서) | — | 미실행 | 병합(PR #1) |
| feature/day-boundary | main | TokTokCore 패키지, DayBoundary·RecordDay·DayBoundaryCalculator | R06 / T02~T06, T08 | Linux 13건 PASS (R-001) | Apple Foundation 실행 NOT RUN | 미실행 | 병합(PR #2) |
| feature/local-storage | day-boundary | TimeRecord, FileRecordRepository, SettingsStore, RecordTimeService | R01 R07 R08 / T01 T07 T09~T15 | Linux 누적 28건 PASS, 저장 테스트 10회 반복 PASS (R-002) | 별도 프로세스 동시 쓰기·잠금 상태 파일 보호 NOT RUN | 미실행 | 병합(PR #3) |
| feature/app-intent | local-storage | Xcode 프로젝트·shared scheme·TokTokTests, RecordNowIntent, AppShortcuts, PrivacyInfo | R02 / T14 | pbxproj 구문 검사 PASS, Xcode 빌드 NOT RUN (R-003) | 컴파일 미확인(TS-005), 실기기 매트릭스 전체 NOT RUN | 미실행 | 병합(PR #4) |
| feature/back-tap-setup | day-screen | 뒷면 탭 연결 도우미: ShortcutsLink, 새 단축어 편집기 열기, 설정 경로 안내, 마지막 단축어 기록 확인, 빈 화면에서 진입 | R03 | Linux 32건 PASS, 앱 화면 NOT RUN (R-005) | 앱이 뒷면 탭 설정 자체는 못 바꿈(TS-006), 이 브랜치 변경은 미컴파일 | 미실행 | 병합(PR #6) |
| feature/day-screen | app-intent | 하루 화면, 첫 경계 설정, 설정, 뒷면 탭 안내, 개인정보 안내 | R03 R04 R05 R06 R09 / T15 T16 | Linux 31건 PASS, 앱 UI NOT RUN (R-004) | TS-004(구분선 대비), TS-005 | 미실행 | 병합(PR #5) |

각 브랜치의 커밋은 `git log main..<브랜치>`로 확인한다.

## 사용한 잠정 정책

QUESTIONS.md 하단 “MVP 구현에 적용한 잠정 정책” 표 참고(Q01~Q11). 제품 확정사항이 아니다.

## 실기기 확인 절차 (사용자)

1. `git switch main` 후 `TokTok.xcodeproj`를 Xcode 16 이상으로 연다.
2. TokTok 타깃 → Signing & Capabilities에서 Team을 고르고, 필요하면 Bundle Identifier(`com.example.TokTok`, 잠정)를 바꾼다.
3. iPhone을 연결하고 개발자 모드를 켠 뒤 Run. 빌드 오류가 나면 오류 전문을 TROUBLESHOOTING.md TS-005에 남기거나 Claude에게 전달한다.
4. 첫 화면에서 하루 시작 시간을 고르고 ‘이 시간으로 시작’.
5. ‘현재 시간 기록’ 버튼 → 블록이 바닥부터 쌓이는지, 앱을 완전히 종료 후 다시 열어도 남는지 확인.
6. 단축어 앱 → TokTok → ‘현재 시간 기록’ 실행 → 앱에 블록이 생기는지 확인.
7. 설정 → 손쉬운 사용 → 터치 → 뒷면 탭 → 두 번/세 번 탭 → ‘현재 시간 기록’ 연결 후 탭.
8. TEST_PLAN.md 실기기 매트릭스(전면/백그라운드/미실행/잠금·화면 켜짐/잠금·화면 꺼짐/재부팅 후 최초 해제 전/강제 종료/네트워크 없음)를 상태별 10회씩 시도하고 결과를 TEST_RESULTS.md에 기록. 잠금·화면 꺼짐에서의 성공은 이 결과 전까지 보장하지 않는다.
9. Mac 터미널에서 `cd TokTokCore && swift test`, 그리고 기기 대상 `xcodebuild ... test`(README 실행 하네스)로 TokTokTests 실행.

## Codex 독립 검증 요청 (인계용)

```text
AGENTS.md에 따라 feature/day-boundary, feature/local-storage, feature/app-intent, feature/day-screen을
순서대로 독립 검증해 주세요(feature/branch-rules는 문서 변경만). 제품 코드는 우선 수정하지 마세요.
특히 앱 타깃이 아직 한 번도 컴파일되지 않았다는 점(TS-005), 하루 경계 DST 정책, 파일 단위 저장소의
멱등성·실패 처리, App Intent의 실행 모드 미선언과 잠금 상태 문구를 확인해 주세요.
결과는 TEST_RESULTS.md와 TROUBLESHOOTING.md에 기록하고 브랜치별 병합 가능 여부를 판정해 주세요.
```

## App Store

실제 제출은 하지 않았다. 남은 준비: 앱 아이콘 이미지(현재 비어 있음), Team·Bundle ID 확정, 개인정보처리방침 URL·지원 URL, 스크린샷, App Privacy 응답, Release 빌드·TestFlight 확인, 실기기 매트릭스 결과 반영.
