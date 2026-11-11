# TokTokTok

iPhone 뒷면을 세 번 톡톡톡 치거나 버튼 한 번으로 **지금 이 순간의 시각**을 남기는 개인 기록 앱입니다. 새벽에 잠깐 깬 순간, 버스에 탄 순간처럼 화면을 오래 보지 않고 남긴 시각을, 내가 정한 하루 시작 시간 기준으로 묶어 보여 줍니다.

- 계정·서버·광고·분석 도구 없음. 기록은 기기 안에만 저장됩니다.
- iOS 17 이상, SwiftUI, 한국어 우선

## 주요 기능

| 기능 | 설명 |
|---|---|
| 현재 시간 기록 | 앱 안 버튼, 뒷면 세 번 탭, 단축어로 입력 없이 지금 시각을 저장(뒷면 탭은 화면이 켜져 있을 때만) |
| 기록 완료 알림 | 소리 없이 기본 진동 한 번(설정에서 끌 수 있음). 앱 안 기록은 위쪽 토스트를 잠깐 표시, 뒷면 탭은 iOS 실행 표시만 |
| 뒷면 탭 연결 | 단축어 만들기 → 손쉬운 사용 › 터치 › 뒷면 탭 › 세 번 탭 연결을 단계별로 안내하고, 연결되면 마지막 기록으로 확인 |
| 사용자 지정 하루 | 하루 시작 시간을 직접 정함(예: 04:00). 자정이 아니라 그 시각에 하루가 바뀜 |
| 하루 화면 | 현재 기록일의 기록 목록과 경계부터 경계까지의 하루 눈금. 날짜는 바뀌는 첫 행에만 표시 |
| 기록 지우기 | 기록 행을 오른쪽으로 밀어 하나씩, 또는 설정의 ‘오늘 기록 지우기’로 오늘 기록 전체(확인 후). 되돌리기 없음 |
| 설정 | 하루 시작 시간(카드 안에서 저장), 메인 색 5가지(호박·산호·세이지·하늘·라벤더), 다크(기본)·라이트, 진동 켜기·끄기 |

> [!NOTE]
> 기록 시각은 단축어가 앱을 실행한 순간이라 손가락으로 탭한 순간과 조금 다를 수 있습니다. 화면이 꺼진 상태에서는 iPhone이 뒷면 탭을 인식하지 않았습니다(실기기 확인, TS-007). 그래서 뒷면 탭 기록은 화면이 켜져 있을 때만 지원합니다(사용자 결정 2026-11-11). 잠금 상태의 Siri 실행도 실기기에서 되지 않아 안내하지 않습니다.

## 시작하기

### 요구 사항

- Xcode 16 이상(확인한 버전: Xcode 26.5), iOS 17 이상 기기 또는 시뮬레이터
- 실기기 설치 시 Apple Developer 계정

### 설치

```sh
git clone https://github.com/6luv/tok-tok-tok.git
cd tok-tok-tok
cp Config/Signing.local.xcconfig.example Config/Signing.local.xcconfig
```

`Config/Signing.local.xcconfig`에 내 번들 ID와 Team ID를 넣은 뒤 `TokTok.xcodeproj`를 열고 실행합니다.

> [!IMPORTANT]
> `Config/Signing.local.xcconfig`는 `.gitignore`에 있어 커밋되지 않습니다. 번들 ID·Team ID·기기 정보는 저장소와 문서에 올리지 않습니다. 이미 설치한 앱의 기록을 유지하려면 그때 쓰던 번들 ID를 그대로 사용하세요.

### 테스트

```sh
# 도메인 로직(하루 경계·저장소·표시 규칙)
cd TokTokCore && swift test

# 앱 타깃(시뮬레이터 UDID는 xcrun simctl list devices 로 확인)
xcodebuild test -project TokTok.xcodeproj -scheme TokTok \
  -destination 'platform=iOS Simulator,id=<시뮬레이터 UDID>'
```

빌드 성공만으로 완료로 보지 않습니다. 실제 실행 결과는 [TEST_RESULTS.md](docs/TEST_RESULTS.md)에 PASS / NOT RUN으로 구분해 기록합니다.

## 프로젝트 구조

```text
TokTok/            앱(SwiftUI)
  Day/             하루 화면, 기록 블록, 하루 눈금, 디자인 토큰(Theme)
  Settings/        첫 실행 경계 설정, 설정, 뒷면 탭 연결, 개인정보 안내
  Intents/         App Intent ‘현재 시간 기록’, App Shortcut
TokTokCore/        도메인 Swift 패키지: 하루 경계 계산, 파일 저장소, 기록 서비스
TokTokTests/       앱 타깃 테스트
Config/            서명 설정(로컬 값은 커밋하지 않음)
docs/              제품·설계·테스트·인계 문서
```

화면·도메인·저장소·Intent를 나눠, 앱 화면을 열지 않고 Intent만 실행돼도 저장할 수 있게 했습니다.

## 문서

제품·설계·테스트 문서는 [`docs/`](docs/)에 있습니다.

| 문서 | 내용 |
|---|---|
| [PRD.md](docs/PRD.md) | 요구사항(R01~R10), 데이터, 하루 경계, iOS 제약 |
| [DESIGN.md](docs/DESIGN.md) | 화면 구조, 디자인 토큰, 상태별 표현, 접근성 |
| [QUESTIONS.md](docs/QUESTIONS.md) | 제품 결정과 잠정 정책 |
| [TEST_PLAN.md](docs/TEST_PLAN.md) | 자동·UI·실기기 테스트와 출시 게이트 |
| [TEST_RESULTS.md](docs/TEST_RESULTS.md) | 실제 실행 증거 |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | 이슈 재현·원인·수정 기록 |
| [SOURCES.md](docs/SOURCES.md) | Apple 공식 근거 |
| [CLAUDE.md](CLAUDE.md) · [AGENTS.md](AGENTS.md) | 구현·검증 담당 규칙, 브랜치 규칙(도구가 자동으로 읽어 저장소 맨 위에 둠) |
| [DEVICE_CHECKLIST.md](docs/DEVICE_CHECKLIST.md) | 실기기에서만 확인할 수 있는 항목 점검표 |
| [HANDOFF.md](docs/HANDOFF.md) | 기능별 인계 |

## 안내 페이지

App Store Connect에 등록할 개인정보처리방침·지원 페이지는 [`site/`](site/)의 정적 HTML이며 Vercel(Hobby, 프로젝트 `toktoktok`)에 배포합니다. 앱 안에는 웹 링크를 두지 않고 같은 내용의 전문(`PrivacyPolicyView`)을 넣었습니다(사용자 결정 2026-11-11). 가이드라인 5.1.1(i)이 앱 안 ‘링크’를 요구하므로 이 방식이 인정될지는 확인되지 않은 심사 위험입니다(`docs/HANDOFF.md`). 두 곳의 문구와 시행일은 함께 고칩니다.

| 페이지 | 주소 |
|---|---|
| 개인정보처리방침 | https://toktoktok-nine.vercel.app/privacy/ |
| 지원 | https://toktoktok-nine.vercel.app/support/ |

배포: `cd site && npx vercel link --project toktoktok`(처음 한 번) 후 `npx vercel deploy --prod` (로그인한 계정에서, `.vercelignore`로 `.env*`·`.vercel` 제외). 보안 헤더(CSP·X-Frame-Options·nosniff·Referrer-Policy·Permissions-Policy·COOP·CORP)는 `site/vercel.json`에서 모든 경로에 붙인다. 페이지에 인라인 스크립트·스타일을 넣으면 CSP에 막히므로 `style.css`만 쓴다.

## 개발 환경 기록

| 항목 | 값 |
|---|---|
| 앱 이름 / 번들 ID | TokTokTok / 저장소 기본값 `com.example.TokTokTok`(실제 값은 로컬 설정 파일) |
| Xcode / Swift | Xcode 26.5(17F42), Apple Swift 6.3.2 (macOS 26.3.1) |
| 최소 iOS | 17.0 (Q09) |
| 프로젝트 / scheme | `TokTok.xcodeproj` / shared scheme `TokTok`(앱 + `TokTokTests`), 로컬 패키지 `TokTokCore` |
| 테스트 시뮬레이터 | iPhone 17 Pro(iOS 26.5). 실기기 기종·OS는 docs/TEST_RESULTS.md에 실행별로 기록 |
| 구현 모델 | Claude Opus 5.5(`claude-opus-5-5`) |
| 검증 모델 | Codex Astra(요청 명칭) → 실제 모델 ID `gpt-6-astra`(codex-cli 0.167.0, ChatGPT 계정 로그인). 2026-11-11 사용자 확인 후 사용. 이전 기본값 `gpt-5.4`는 이 계정에서 지원되지 않아 PR #11~#24 병합 전 검증 미실행 |

<details>
<summary>구현·검증 인계 프롬프트</summary>

구현:

```text
CLAUDE.md, AGENTS.md 및 연결 문서를 읽고 PRD의 요구사항 ID별로 구현해 주세요.
docs/QUESTIONS.md의 잠정 정책을 확정사항으로 바꾸지 말고, 독립적으로 가능한 작업부터 진행해 주세요.
모델과 도구 버전, 변경 파일, 실제 테스트 결과, 알려진 제약을 남기고 Codex 검증에 인계해 주세요.
```

독립 검증:

```text
AGENTS.md에 따라 현재 변경을 독립 검증해 주세요. 제품 코드는 우선 수정하지 마세요.
docs/PRD.md R01~R10, docs/DESIGN.md, docs/TEST_PLAN.md를 구현 및 실제 실행 결과와 대조해 주세요.
하루 경계·DST·동시 저장·잠금/화면 꺼짐 실행과 과장된 지원 약속을 중점 확인해 주세요.
실기기가 없으면 관련 항목은 NOT RUN 또는 BLOCKED로 남겨 주세요.
docs/TEST_RESULTS.md와 docs/TROUBLESHOOTING.md에 증거·재현·심각도·출시 차단 여부를 기록해 주세요.
```

</details>
