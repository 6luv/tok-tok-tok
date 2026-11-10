# 시간 기록 앱 — 복사 가능한 개발 문서 세트

문서 작성 완료, 앱 구현 전 상태이다. 이 폴더의 Markdown 파일들을 새 앱 저장소 루트에 복사해 사용한다. 이 README.md를 시작점으로 삼는다. 지침 파일을 읽는 도구의 설정과 실제 선택 모델은 별도로 확인한다. 문서만으로 모델 실행이나 에이전트 간 자동 인계가 설정되지는 않는다.

## 파일 역할

| 파일 | 용도 |
|---|---|
| PRD.md | 요구사항·데이터·하루 경계·iOS 제약 |
| DESIGN.md | 다크 화면·한 판 기록 목록·위쪽 쌓기·접근성 |
| CLAUDE.md | Claude 구현 규칙·순서·인계 |
| AGENTS.md | 공통 제약·Codex 독립 검증 |
| QUESTIONS.md | 미결정 제품 질문과 잠정 처리 |
| TEST_PLAN.md | 자동·UI·실기기 테스트 및 출시 게이트 |
| TEST_RESULTS.md | 실제 실행 증거와 통과/미실행 기록 |
| TROUBLESHOOTING.md | 재현·원인·수정·회귀 검증 기록 |
| SOURCES.md | Apple 공식 근거 |

하루 경계는 사용자 지정이다. 06:00·23:00 고정값을 적용하지 않는다. 최초 설정 방식·과거 재분류·시간대·쌓기 순서는 QUESTIONS.md에서 확인한다.

## 환경 기록 — 프로젝트 생성 후 채우기

| 항목 | 값 |
|---|---|
| 앱 이름 / Bundle ID | TokTokTok / 저장소 기본값 `com.example.TokTokTok`. 실제 번들 ID·Team ID는 커밋하지 않는 `Config/Signing.local.xcconfig`에 둔다(예시: `Config/Signing.local.xcconfig.example`) |
| Xcode / Swift / SDK | 사용자 Mac에서 확인 필요(이 세션에서 Xcode 실행 불가, TS-001). 프로젝트 형식은 objectVersion 77이라 Xcode 16 이상 필요. 도메인 테스트: Swift 6.4.1 Linux |
| 최소 iOS | 17.0 (Q09 잠정 제안 채택, 미확정) |
| project 또는 workspace / shared scheme | `TokTok.xcodeproj` / shared scheme `TokTok` (앱 + `TokTokTests`). 도메인 패키지 `TokTokCore` (로컬 Swift 패키지) |
| 테스트 simulator ID / 실기기 기종·OS | 시뮬레이터 사용 안 함(사용자 결정, 저장공간). 실기기 기종·OS는 사용자 확인 후 기록 |
| 구현 모델 | 요청 명칭 Claude Opus 5.5; 세션 구성 모델 ID `claude-opus-5-5` (실제 응답 모델은 런타임에 따라 다를 수 있음) |
| 검증 모델 | 요청 명칭 Codex Astra; 실제 제공 ID 확인 필요 |

## 실행 하네스

프로젝트 생성 후 실제 파일명·scheme·destination으로 다음 템플릿을 채운다. 꺾쇠 자리표시자를 그대로 실행하지 않는다. workspace를 만들었다면 -project 대신 -workspace를 사용한다.

도메인 로직(Mac 터미널 또는 Linux):

```sh
cd TokTokCore && swift test
```

실기기(사용자 iPhone) 대상 앱 빌드·테스트:

```sh
xcodebuild -version
xcodebuild -list -project TokTok.xcodeproj
xcodebuild -project TokTok.xcodeproj -scheme TokTok -destination 'generic/platform=iOS' build
xcodebuild -project TokTok.xcodeproj -scheme TokTok -destination 'platform=iOS,id=<연결한 iPhone UDID>' -resultBundlePath build/TokTok-device.xcresult test
```

참고용 원래 템플릿:

```sh
xcodebuild -version
xcodebuild -list -project '<실제 프로젝트>.xcodeproj'
xcodebuild -showdestinations -project '<실제 프로젝트>.xcodeproj' -scheme '<공유 scheme>'
xcodebuild -project '<실제 프로젝트>.xcodeproj' -scheme '<공유 scheme>' -destination 'platform=iOS Simulator,id=<실제 UUID>' -resultBundlePath '<새 결과 경로>.xcresult' test
```

CI를 구성한다면 동일한 공유 scheme과 사용 가능한 simulator를 지정하고 SDK·Xcode 버전을 기록한다. 결과 bundle과 요약을 보관하되 개인 데이터·서명 정보는 제외한다. 자동 테스트 CI와 실기기 수동 검증을 별도 게이트로 둔다. 앱 프로젝트가 없으므로 실행 스크립트나 CI 성공 결과는 이 세트에 포함하지 않았다.

## 구현 시작 프롬프트

```text
CLAUDE.md, AGENTS.md 및 연결 문서를 읽고 PRD의 요구사항 ID별로 구현해 주세요.
하루 경계는 사용자가 지정하며 최초 기본값은 미정입니다.
QUESTIONS.md의 잠정 정책을 확정사항으로 바꾸지 말고, 독립적으로 가능한 작업부터 진행해 주세요.
우선 시간 경계 계산·로컬 저장·App Intent의 실기기 실행 가능성을 검증해 주세요.
모델과 도구 버전, 변경 파일, 실제 테스트 결과, 알려진 제약을 남기고 Codex 검증에 인계해 주세요.
```

## 독립 검증 프롬프트

```text
AGENTS.md에 따라 현재 변경을 독립 검증해 주세요. 제품 코드는 우선 수정하지 마세요.
PRD R01~R10, DESIGN.md, TEST_PLAN.md를 구현 및 실제 실행 결과와 대조해 주세요.
하루 경계·DST·동시 저장·잠금/화면 꺼짐 실행과 과장된 지원 약속을 중점 확인해 주세요.
실기기가 없으면 관련 항목은 NOT RUN 또는 BLOCKED로 남겨 주세요.
TEST_RESULTS.md와 TROUBLESHOOTING.md에 증거·재현·심각도·출시 차단 여부를 기록해 주세요.
```
