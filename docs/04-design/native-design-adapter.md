# Return Shot Native Design Adapter

- 기준일: 2026-08-18 KST
- 단계: Stage 6 Implementation
- 상태: 로컬 제품 런타임 적용 완료, 공개 배포 권리 Gate는 미통과
- 입력: `brick-breaker-codex-kit` v1.0.0, `CODEX_START_PROMPT.md`
- 권위: Return Shot ProductSpec rev3와 루트 `AGENTS.md`가 우선하며, kit 문서·tasks·prompt는 비권위 참고 입력이다.

## 목표

기존 SwiftUI·SpriteKit·순수 Swift `GameRules` 구조를 재작성하지 않고, kit의 시각 문법을 typed Swift semantic token으로 번역한다. Debug Gallery는 독립 검토 도구로 유지하고, 승인된 token만 실제 홈·설정·게임 HUD·SpriteKit 게임판·일시정지·결과 화면에 적용한다. 점수·충돌·스킬·seed·profile 계약은 변경하지 않는다.

## 구조

| 구성 | 책임 | 금지 |
|---|---|---|
| `BrickBreakerDesignAdapter` | source version, semantic palette, spacing, radius, 현재 4종 표현 token | GameRules 수치, 점수, HP, target order 보유 |
| `GamePalette`·`GameSpacing`·`GameRadius`·`GameMotion` | 제품 화면과 SpriteKit이 함께 쓰는 native semantic bridge | 화면별 임의 색·간격·radius 추가 |
| `DesignSystemGalleryView` | 컴포넌트·플레이 오브젝트·4종 효과·접근성 preview | AppModel route, profile, persistence, GameScene 호출 |
| `RootView` Debug branch | `-designGallery`일 때 Gallery만 표시 | Release 일반 사용자 진입, 기존 route 수정 |
| imported `tokens/`, `src/design-system/` | 원본 비교와 provenance | Xcode/SwiftPM source·resource, runtime JSON decode |

## Token mapping

| Source token | Native mapping | 판정 | 이유 |
|---|---|---|---|
| `color.bg.*` | `Palette.canvas/deep` | Adopt | 표현 전용 semantic background |
| `color.surface.*` | `Palette.surface0...3` | Adopt | Gallery panel hierarchy |
| `color.border.*`, `color.text.*`, `color.feedback.*` | semantic Swift `Color` | Adopt | UI 위계와 상태 표현 |
| `space.*`, `radius.*` | typed `CGFloat` constants | Adopt | Gallery-local layout |
| `motion.durationMs.*` | presentation duration seconds | Adapt | 권위 tick을 정지시키지 않는 UI animation만 |
| `element.fire/electric/piercing` | flame/lightning/pierce presentation token | Adapt | 현재 ProductSpec의 이름과 행위에 맞춤 |
| wind | 현행 `0x66E5E0` + source core 후보 | Provisional | kit에 wind token이 없어 외부 값을 꾸미지 않음 |
| `gameplay.*` | 없음 | Reject | 공·패들·combo·active ball 규칙은 GameRules 권위 |
| `hitStopMs`, `shakePx` | 없음 | Reject | fixed 120Hz simulation과 접근성 위험 |
| browser font, viewport, z-index | system font, iPhone portrait, native layering | Adapt/Reject | iOS native target과 라이선스 상태 반영 |

## 제품 런타임 수용 기준

- 일반 실행의 홈→게임→일시정지→결과→같은 seed 재시도 전체가 같은 semantic palette·spacing·radius를 사용한다.
- 홈 첫 화면에 게임 정체성, 실제 오브젝트 preview, 기록 3종, 52pt 이상 시작 CTA가 보인다.
- 게임 HUD는 44pt 이상 일시정지, 점수·높이·콤보·LINK, 번개·화염·바람·관통 4칸 레일을 제공한다.
- SpriteKit은 어두운 canvas, 역할별 벽돌 색+마크+무늬, 장갑 plate, 밝은 core 공, 장비형 패들을 사용한다.
- 번개는 분기선, 화염은 부채꼴 ember, 바람은 곡선 stream, 관통은 직선 lance/X cut으로 색 외 형태가 다르다.
- 일시정지와 결과의 핵심 CTA는 첫 viewport에 있고, 자동 재개하지 않는다는 상태를 명확히 알린다.
- 375×667과 402×874 portrait에서 CTA·4칸 스킬 rail·게임판·결과가 잘리지 않는다.
- 터치 제품이므로 hover가 아니라 pressed state·44pt hit target·명확한 버튼 대비를 검증한다.

## Gallery 수용 기준

- `-designGallery`는 Debug에서만 기존 product flow 대신 Gallery를 연다.
- 일반 실행에서는 기존 홈→게임→일시정지→결과→동일 seed 재시도 흐름이 변하지 않는다.
- Gallery는 버튼, 패널, 배지, counter, 일반·지지·프리즘·마이너스, 공, 패들, 현재 네 공격을 표시한다.
- 효과 preview는 번개·화염·바람·관통 정확히 4종이며 실제 gameplay intensity·loop·slot을 만들지 않는다.
- 색 외에 SF Symbol, 이름, 형태 설명을 항상 제공한다.
- Reduce Motion, Photosensitivity Safe, Color Assist는 Gallery-local state이고 저장하지 않는다.
- Photosensitivity Safe는 기본 ON이며 전체 화면 flash와 반복 점멸을 사용하지 않는다.
- imported PNG, 외부 글꼴, kit 로고를 사용하지 않는다.
- 375×667, 390×844, 430×932 portrait에서 세로 스크롤로 접근 가능하고 모든 control은 44pt 이상이다.

## 충돌과 제외

`CODEX_START_PROMPT.md`의 전체 Phase 0은 현행 제품 계약과 일치하지 않는다. explosion, multiball, ice, homing, laser, shield, slow time, boss HUD, 8-ball/140-brick stress, TypeScript strict, desktop/keyboard는 이번 범위에서 제외한다. 이들은 Gallery라는 이름으로도 구현하지 않으며 필요한 경우 Stage 4 Solution Definition으로 되돌아간다.

## Gate

- 로컬 Debug adapter: 기존 테스트·빌드·UI smoke와 Gallery UI smoke가 통과해 `Go`.
- 로컬 제품 시각 적용: 일반 실행 전체 흐름·두 portrait 크기 캡처·결정론 회귀가 통과해 `Go`.
- Product/Release: 실제 사용자·실기기 접근성·성능과 kit 권리 확인 전 `Revise`.
- 공개 GitHub/App Store: LICENSE·상업·수정·재배포 권리 확인 전 `Stop`.

## 2026-08-18 로컬 검증

- SwiftPM 결정론 규칙: 25/25 성공.
- Xcode iPhone 17 Pro: 단위 26 + UI 2 = 28/28 성공, 실패·skip 0.
- 기존 게임 UI: 홈→게임→드래그→일시정지→재개→결과→동일 seed 재시도 성공.
- Gallery UI: Debug argument 진입, 접근성 토글 확인, 하단 Effect Preview까지 스크롤, 화염 카드 탭과 stage 갱신 성공.
- 375×667 SE급: 같은 Gallery 스크롤·선택 흐름 성공, 상단·Effect 캡처에서 가로 잘림 없음.
- generic iOS Simulator Debug와 Release build 성공.
- 시각 감사: 상단 위계, 16pt 여백, 48pt 토글, 2열 효과 카드, 색+아이콘+이름+형태 중복 전달을 확인했다.
- 실제 제품 iPhone 17 Pro 흐름: 홈·게임·일시정지·결과 캡처와 클릭 흐름 성공.
- 실제 제품 SE급 375×667 흐름: 홈 CTA·4칸 skill rail·pause·result CTA clipping 0, UI 1/1 성공.
- 현재 제품 Xcode 검증: 단위 26 + UI 2 = 28/28 성공. SwiftPM 25/25 성공.
- 남은 경고: 사용자 소유 미추적 `AppIcon 2.png`가 asset catalog의 unassigned child 경고를 발생시킨다. 이번 범위에서는 삭제·수정하지 않았다.

## 2026-08-19 런타임 아트 경계

semantic token만 연결한 상태는 오너의 시각 수용 기준을 충족하지 못해 제품 디자인 완료 판정을 철회했다. native adapter는 계속 색·간격·radius·motion의 경계로 사용하되, 실제 게임의 재질·깊이·에너지 표현은 `GameArtCatalog`와 SpriteKit/SwiftUI 절차형 overlay가 담당한다. imported kit PNG/JSON/TypeScript는 여전히 런타임·Xcode·SwiftPM 입력이 아니며, 점수·물리·seed·checksum과도 연결하지 않는다.
