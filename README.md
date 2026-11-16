<p align="center">
  <img src="TokTokTok/Assets.xcassets/AppIcon.appiconset/AppIcon-dark.png" width="120" alt="TokTokTok 앱 아이콘">
</p>

<h1 align="center">TokTokTok · 톡톡톡</h1>

<p align="center">
  iPhone 뒷면을 세 번 톡톡톡 치면, 지금 이 순간의 시각이 남아요.
</p>

<p align="center">
  <a href="https://apps.apple.com/kr/app/id6835431665"><img src="https://img.shields.io/badge/App_Store-%ED%86%A1%ED%86%A1%ED%86%A1-0D96F6?logo=apple&logoColor=white" alt="App Store에서 보기"></a>
  <img src="https://img.shields.io/badge/iOS-17%2B-1B1A18" alt="iOS 17 이상">
  <img src="https://img.shields.io/badge/SwiftUI-Swift_6-F0B45A" alt="SwiftUI, Swift 6">
</p>

> [!NOTE]
> 2026년 11월 16일 App Store 심사에 제출했어요. 승인되어 출시되기 전에는 App Store 링크가 열리지 않아요.

<p align="center">
  <img src="docs/appstore/marketing-6.3/01-backtap.png" width="160" alt="뒷면 세 번 톡톡톡, 지금 시각이 바로 기록돼요">
  <img src="docs/appstore/marketing-6.3/02-my-day.png" width="160" alt="내가 정하는 하루">
  <img src="docs/appstore/marketing-6.3/03-connect.png" width="160" alt="한 번만 연결하면 끝">
  <img src="docs/appstore/marketing-6.3/04-settings.png" width="160" alt="내 취향대로 조용하게">
  <img src="docs/appstore/marketing-6.3/05-start.png" width="160" alt="자정이 아니어도 괜찮아요">
</p>

## 어떤 앱인가요

새벽에 잠깐 깬 시각, 약을 먹은 시각, 버스에 탄 시각처럼 **글을 쓰지 않고 시각만 남기고 싶은 순간**을 위한 앱이에요. 뒷면을 세 번 치거나 버튼을 한 번 누르면 끝이고, 기록은 내가 정한 하루 시작 시간을 기준으로 묶여 보여요.

- 계정·서버·광고·분석 도구가 없어요. 기록은 iPhone 안에만 저장돼요.
- 무료, 앱 안 결제 없음
- iOS 17 이상, 한국어

## 주요 기능

| 기능 | 설명 |
|---|---|
| 지금 시각 기록 | 앱 안 버튼, 뒷면 세 번 탭, 단축어로 입력 없이 저장해요. 뒷면 탭은 화면이 켜져 있을 때만 돼요 |
| 기록 알림 | 저장되면 짧은 마림바 소리와 진동이 한 번 나요. 설정에서 각각 끌 수 있고, 무음 모드에서는 소리가 나지 않아요 |
| 뒷면 탭 연결 안내 | 단축어 만들기부터 손쉬운 사용 › 터치 › 뒷면 탭 › 세 번 탭 연결까지 단계별로 안내하고, 연결되면 마지막 기록으로 확인해요 |
| 내가 정하는 하루 | 하루 시작 시간을 직접 정해요(예: 04:00). 새벽 기록이 전날 기록과 함께 보여요 |
| 하루 화면 | 경계부터 경계까지의 하루 눈금과 최신순 기록 목록. 날짜는 바뀌는 첫 기록에만 보여요 |
| 기록 지우기 | 기록을 오른쪽으로 밀어 하나씩, 또는 설정의 ‘오늘 기록 지우기’로 한꺼번에 지워요 |
| 설정 | 하루 시작 시간, 메인 색 5가지, 다크·라이트, 소리·진동 |

> [!NOTE]
> 기록 시각은 단축어가 앱을 실행한 순간이라 손가락으로 탭한 순간과 조금 다를 수 있어요. 화면이 꺼진 상태에서는 iPhone이 뒷면 탭을 인식하지 않아서, 뒷면 탭 기록은 화면이 켜져 있을 때만 지원해요([TS-007](docs/TROUBLESHOOTING.md)).

## 개인정보

앱은 아무 데이터도 수집하거나 보내지 않아요. 기록과 설정은 기기 안에 저장되고, 사용자가 켜 둔 iCloud·컴퓨터 백업에만 포함될 수 있어요.

- 개인정보처리방침: https://toktoktok-nine.vercel.app/privacy/
- 지원: https://toktoktok-nine.vercel.app/support/
- 문의: toktoktok.support@gmail.com

## 직접 빌드하기

### 요구 사항

- Xcode 16 이상(확인한 버전: Xcode 26.5)
- iOS 17 이상 기기 또는 시뮬레이터. 실기기 설치에는 Apple Developer 계정이 필요해요

### 설치

```sh
git clone https://github.com/6luv/tok-tok-tok.git
cd tok-tok-tok
cp Config/Signing.local.xcconfig.example Config/Signing.local.xcconfig
```

`Config/Signing.local.xcconfig`에 내 번들 ID와 Team ID를 넣고 `TokTokTok.xcodeproj`를 열어 실행해요.

> [!IMPORTANT]
> `Config/Signing.local.xcconfig`는 `.gitignore`에 있어 커밋되지 않아요. Xcode의 Signing & Capabilities에서 Team을 고르면 그 값이 `project.pbxproj`에 들어가니, 커밋하지 말고 로컬 설정 파일로 옮겨 주세요.

### 테스트

```sh
# 도메인 로직(하루 경계·저장소·표시 규칙)
cd TokTokTokCore && swift test

# 앱 타깃(시뮬레이터 UDID는 xcrun simctl list devices 로 확인)
xcodebuild test -project TokTokTok.xcodeproj -scheme TokTokTok \
  -destination 'platform=iOS Simulator,id=<시뮬레이터 UDID>'
```

실제 실행 결과는 [TEST_RESULTS.md](docs/TEST_RESULTS.md)에 PASS / NOT RUN으로 나눠 적어요. 빌드 성공만으로 완료로 보지 않아요.

## 구조

```text
TokTokTok/          앱(SwiftUI)
  Day/              하루 화면, 기록 블록, 하루 눈금, 디자인 토큰(Theme)
  Settings/         첫 실행 경계 설정, 설정, 뒷면 탭 연결, 개인정보 안내
  Intents/          App Intent ‘현재 시간 기록’, App Shortcut
TokTokTokCore/      도메인 Swift 패키지: 하루 경계 계산, 파일 저장소, 기록 서비스
TokTokTokTests/     앱 타깃 테스트
Config/             서명 설정(로컬 값은 커밋하지 않음), Info.plist
site/               개인정보처리방침·지원 정적 페이지(Vercel)
docs/               제품·설계·테스트·출시 문서
```

화면, 도메인, 저장소, App Intent를 나눠서 앱 화면을 열지 않고 Intent만 실행돼도 기록이 저장돼요. 저장소는 기록 1건을 JSON 파일 1개로 저장해 여러 프로세스가 동시에 써도 서로 덮어쓰지 않아요.

## 문서

| 문서 | 내용 |
|---|---|
| [PRD.md](docs/PRD.md) | 요구사항(R01~R10), 데이터, 하루 경계, iOS 제약 |
| [DESIGN.md](docs/DESIGN.md) | 화면 구조, 디자인 토큰, 상태별 표현, 접근성 |
| [QUESTIONS.md](docs/QUESTIONS.md) | 제품 결정과 잠정 정책 |
| [TEST_PLAN.md](docs/TEST_PLAN.md) · [TEST_RESULTS.md](docs/TEST_RESULTS.md) | 테스트 계획과 실제 실행 결과 |
| [DEVICE_CHECKLIST.md](docs/DEVICE_CHECKLIST.md) | 실기기에서만 확인할 수 있는 항목 |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | 이슈 재현·원인·수정 기록 |
| [SOURCES.md](docs/SOURCES.md) | Apple 공식 문서 근거 |
| [HANDOFF.md](docs/HANDOFF.md) | 기능별 인계와 출시 진행 기록 |
| [appstore/](docs/appstore/) | App Store 등록 문구, 스크린숏, 심사 메모 |

## AI와 함께 만든 앱

이 앱은 AI 코딩 도구와 함께 만들었어요. 구현은 Claude Opus 5.5(`claude-opus-5-5`), 독립 검증은 Codex(`gpt-6-astra`)가 맡았고, 제품 결정은 모두 사람이 내렸어요. 두 도구가 따르는 규칙은 [CLAUDE.md](CLAUDE.md)와 [AGENTS.md](AGENTS.md)에 있어요. 검증을 실행하지 못한 변경은 PR과 [HANDOFF.md](docs/HANDOFF.md)에 ‘Codex 검증 미실행’으로 남겼어요.

| 항목 | 값 |
|---|---|
| Xcode / Swift | Xcode 26.5(17F42), Apple Swift 6.3.2 (macOS 26.3.1) |
| 최소 iOS | 17.0 |
| 프로젝트 / scheme | `TokTokTok.xcodeproj` / shared scheme `TokTokTok`(앱 + `TokTokTokTests`), 로컬 패키지 `TokTokTokCore` |
| 테스트 시뮬레이터 | iPhone 17 Pro(iOS 26.5) |
