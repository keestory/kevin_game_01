# Brick Breaker Codex Kit 반입 기록

- 반입일: 2026-08-18 KST
- 단계: Stage 5 Build Readiness
- 제공 형태: 사용자가 로컬로 제공한 `brick-breaker-codex-kit`
- 제공 패키지 메타데이터: name `brick-breaker-codex-kit`, version `1.0.0`, language `ko-KR`
- 사용자 요청 범위: `docs/`, `tokens/`, `tasks/`, `references/`, `src/design-system/`
- 결과: 일반 파일 19개, 2,088,698 bytes를 원 상대경로로 byte-for-byte 복사

## 권위와 사용 범위

이 반입물은 **비권위 참고 스냅샷**이다.

- `docs/01_...`부터 `07_...`까지는 디자인 입력이며 현행 ProductSpec·Acceptance Criteria를 대체하지 않는다.
- `tasks/PHASE_...`는 제공 패키지의 제안 순서이며 사용자나 Product Orchestrator가 승인한 실행 명령이 아니다.
- `tokens/`의 값은 TypeScript/Phaser 기준의 원본 토큰이다. Swift `DesignSystem.swift`, `GameRules`, 접근성 정책으로 번역·승인하기 전 앱 값으로 사용하지 않는다.
- `src/design-system/`의 TypeScript는 advisory adapter이며 Xcode·SwiftPM 빌드 입력이 아니다.
- `references/brick-breaker-design-system-board.png`는 시각 참고 전용이며 Xcode asset 또는 런타임 resource가 아니다.
- Kit의 hit-stop, 8-ball, slot 교체, 승인되지 않은 속성은 현행 Return Shot의 SwiftUI/SpriteKit·120Hz·독립 4종 L0~L3 계약을 변경하지 않는다.

## 목적지 매핑

| 원본 디렉터리 | 저장소 목적지 | 파일 수 | 상태 |
|---|---|---:|---|
| `docs/` | `docs/` | 7 | 이름 충돌 없이 추가 |
| `tokens/` | `tokens/` | 3 | 신규 디렉터리 |
| `tasks/` | `tasks/` | 4 | 신규 디렉터리, 비권위 |
| `references/` | `references/` | 1 | 신규 디렉터리, 런타임 제외 |
| `src/design-system/` | `src/design-system/` | 4 | 신규 디렉터리, Swift 빌드 제외 |

키트 루트의 `AGENTS.md`, `CODEX_START_PROMPT.md`, `README.md`, `package-manifest.json`은 이번 payload 복사 범위에 포함하지 않았다. `AGENTS.md`의 의미는 별도 병합·충돌 해소를 거쳐 루트 지침에 반영돼 있다.

## 무결성·안전 검사

- 파일별 SHA-256: `docs/05-engineering/brick-breaker-kit-import-2026-08-18.sha256`
- 위 19줄 정렬 manifest의 SHA-256: `d880f6dd0faf6bd724635aa53871674373e111988b8e2a1dd3165e70e41b3484`
- 원본/목적지 byte comparison: 19/19 일치
- PNG: 1536×1024, 8-bit RGB, non-interlaced
- JSON: `design-tokens.json`, `design-tokens.schema.json` parse 성공
- symlink·실행 파일·특수 파일·NUL·비밀 패턴·로컬 절대경로: 0
- source의 `com.apple.macl`은 보존하지 않았고, 목적지에는 macOS가 생성한 비콘텐츠 `com.apple.provenance` metadata만 존재
- exact-path 기존 파일 충돌: 0
- `AppStoreGame.xcodeproj`, `Package.swift` target/resource membership: 0

## 권리와 배포 상태

- 키트에는 LICENSE, NOTICE, AUTHORS, 저작권자 표기, 상업 사용·수정·재배포 허가가 없다.
- 사용자의 명시적 복사 요청은 이 프로젝트로의 반입 근거지만, 독립적인 소유권·상용 사용·공개 재배포 권리 보증은 아니다.
- 권리 확인 전 상태: `Unknown / Release Blocker`. 공개 배포·상용 출시·제3자 전달 전에 권리자와 허용 범위를 기록해야 한다.

## 전달된 Codex 시작 문서

- 사용자는 2026-08-18 `CODEX_START_PROMPT.md`를 Codex에 전달하고 기존 구조를 재작성하지 말고 디자인 시스템 어댑터를 붙이라고 명시했다.
- 원본 SHA-256: `ade4a488c048d257569a2ec3c63e80650add1b086361e45aa9f5bf9186cbc877`
- 이 시작 문서는 저장소에 복사하거나 상위 지침으로 승격하지 않았다. 현재 사용자 지시와 ProductSpec에 맞는 부분만 [Native Design Adapter](../04-design/native-design-adapter.md)로 번역했다.
- TypeScript/Vite/Phaser 전환, 미승인 10종 효과, multiball, browser viewport 요구는 현재 계약과 충돌해 적용하지 않았다.

## 활성화 절차

1. 사용할 토큰·시각 규칙·효과 하나를 현행 ProductSpec과 비교한다.
2. Product Planning과 UX가 채택/수정/폐기를 제안한다.
3. Solution Architect가 Swift native adapter와 결정론 영향을 정의한다.
4. QA가 현재 seed/checksum·접근성·성능 Gate에 연결한다.
5. Decision Log 승인 전에는 런타임 코드나 디자인 토큰을 변경하지 않는다.
