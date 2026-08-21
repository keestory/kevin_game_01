# Descent Breaker GPT Combat Signature v1

- 확인일: 2026-08-21 KST
- 단계: Stage 6 Implementation
- 이번 Gate: 로컬 prototype `Go`
- Release Readiness: `Revise`

## 목표와 범위

현재 Ranked Endless의 규칙, 충돌, 점수, 난이도와 사용자 흐름을 바꾸지 않고 GPT 생성 디자인 자산으로 공격의 속성 정체성과 플레이어 기체의 공격 기원을 더 선명하게 만든다.

이번 범위는 다음 세 자산에 한정한다.

1. 전기: 직선 레이저와 구별되는 다중 분기 relay impact core
2. 바람: 끊겨 보이지 않는 이중 곡선과 상승 chevron lift core
3. 플레이어: 기체보다 낮은 시각 우선순위를 가진 reactor aura

## 참여 에이전트 판정

| 역할 | 책임 | 결론 |
|---|---|---|
| Product Orchestrator | 범위·충돌·Gate 통합 | 3개 additive presentation adapter만 채택 |
| Strategy / Market / Red Team | 2026 한국 스토어·인접 장르·차별화 반증 | 화려함의 양보다 실루엣·궤적 문법을 우선 |
| Product Planning / UI·UX / Technical Art | 계층·모션·접근성·A/B 기준 | 위험·탄환·HP를 가리지 않는 origin motif 채택 |
| Solution Architect / iOS Engineering / QA | 비권위 경계·메모리·회귀 | `GameRules` 불변, bounded texture와 DEBUG showcase로 검증 |

## 시장 근거

2026-08-21에 대한민국 iPhone Games 무료와 Action 무료 차트를 분리해 확인했다. 인접 세로 슈팅·생존 액션은 픽셀 캐릭터, 기체, 장비·강화처럼 즉시 식별 가능한 형태를 전면에 둔다. 그러나 차트 관측만으로 특정 아트 스타일이나 VFX가 순위의 원인이라고 결론 내릴 수 없다.

- 공식 Apple 대한민국 iPhone Games 무료: https://apps.apple.com/kr/iphone/charts/6014?chart=top-free
- 공식 Apple 대한민국 iPhone Action 무료: https://apps.apple.com/kr/iphone/charts/7001?chart=top-free
- Metal Slug Rush: https://apps.apple.com/kr/app/metal-slug-rush/id6775727338
- Survivor.io 편집 콘텐츠: https://apps.apple.com/kr/iphone/story/id1639936211
- Wing Fighter: https://apps.apple.com/kr/app/wing-fighter/id1562065271
- 최고매출 보조 관측: https://gamerank.net/en/rankings?chart=top_grossing&country=kr&platform=ios, https://appstorestatistics.com/charts/kr/top-grossing/games, https://emberpicks.com/kr/appstore/games/all/grossing/

제3자 최고매출 순위는 서로 일부 불일치하므로 관측 시점의 외부 추정으로만 사용했다. 이번 구현의 시장 성과·체류 개선·한국 App Store 1위 가능성을 증명하지 않는다.

## Imagegen → Integration → Vision

OpenAI 내장 Imagegen에 현재 `DB_PlayerAttacks`와 `DB_SkillVFX`를 스타일 참고로 제공했다. 최초 투명 생성과 배경 제거 편집은 모두 실제 alpha가 없는 RGB 체크무늬를 반환해 6개 후보를 반려했다. 최종 3개는 순수 검정 배경의 additive 전용 RGB로 다시 생성했다.

최종 프롬프트 규칙:

- 공통: 단일 centered VFX, pure black background, no text, no number, no logo, no watermark, no UI, no ship, no enemy, no full-screen flash
- 전기: 5방향 분기 cyan relay, 짧은 branching arc, orange-white origin core, straight laser 금지
- 바람: cyan double-curve lift, upward chevron, 짧은 particle flow, giant tornado 금지
- 기체 오라: 얇은 cyan ellipse, 작은 orange reactor core, 짧은 exhaust, opaque platform 금지

원본과 해시는 `docs/ASSET_PROVENANCE.md`에 기록했다. 런타임 파생본은 각 축 512px 이하이며 합계 디코딩 메모리는 약 2.8MiB다.

## A/B 비교

| 변형 | 구성 | 판정 |
|---|---|---|
| A — Baseline | 절차형 전기 branch와 바람 curve, 기존 기체 | 기술 기준선으로 보존 |
| B — GPT Signature | A의 실제 origin·target path를 보존하고 전기/바람 core와 기체 aura를 additive 합성 | 로컬 prototype 채택 |

- A: `docs/screenshots/descent-2026-08-21-combat-balance/endless-vfx-continuity-after.png`
- B: `docs/screenshots/descent-2026-08-21-gpt-combat-signature/variant-b-gpt-assets-active.png`

B는 에셋 포함 상태의 build·UI flow·Vision 검사에 통과했다. 다만 최소 5명 블라인드 선호 실험은 실행하지 않았으므로 사용자 선호 우위는 미확인이다.

## 제품 디자인·QA 검사

| 기준 | 실제 관측 | 판정 |
|---|---|---|
| 시각적 위계 | 플레이어, danger line, 적 탄환, Brute HP가 새 VFX보다 선명함 | Pass |
| 간격 | 전기·바람 motif가 실제 충돌 origin 주변에 제한되고 HUD와 겹치지 않음 | Pass |
| 대비 | iPhone SE의 어두운 필드에서 cyan/orange 속성 cue 식별 가능 | Pass |
| 텍스트 가독성 | 점수·콤보·레벨·HP·스킬 레일이 가려지지 않음 | Pass |
| 반응형 레이아웃 | 375×667 portrait에서 확인 | Partial; 390×844, 430×932 미확인 |
| hover 상태 | native iOS touch game에 해당 없음 | N/A |
| 모바일 사용성 | 새 에셋은 입력 hit area를 만들지 않고 기존 lane 조작을 방해하지 않음 | Pass |
| 클릭 가능 요소 | pause와 기존 SwiftUI CTA·선택 상태 불변 | Pass |
| 사용자 흐름 | 기체 선택 → Ranked Endless → 위협/공격 노출 UI 자동화 통과 | Pass |
| 접근성 | Reduce Motion에서 신규 VFX alpha 감소 | Partial; 수동 전체 matrix 미실행 |

## 추출한 디자인 규칙

1. 속성은 색뿐 아니라 궤적 형태로 구분한다: 전기=분기, 바람=이중 곡선·상승.
2. 생성 자산은 판정을 표현하는 origin motif이며 권위 좌표·target path를 대체하지 않는다.
3. additive 자산은 순수 검정 배경, bounded size, 짧은 수명, 낮은 alpha를 함께 만족해야 한다.
4. 정보 우선순위는 `즉시 위험 → 기체·공격 궤적 → 적 HP → 스킬 장식 → 배경`을 유지한다.
5. 한 화면에서 강한 glow는 origin과 플레이어 reactor처럼 의미가 있는 지점에만 사용한다.
6. 투명도가 확인되지 않은 생성물을 RGBA로 기록하거나 불투명 오브젝트로 사용하지 않는다.
7. Reduce Motion·광과민 모드는 권위 simulation을 바꾸지 않고 presentation만 줄인다.

## 검증 결과

- SwiftPM rules: 86 passed, 0 failed
- Xcode Debug Simulator build: succeeded
- `GameArtCatalogTests`: 6 passed, 0 failed
- 신규 GPT asset load/budget test: passed
- `testRankedEndlessCombatV2ExposesThreatAndHostileAttack`: passed
- Vision 직접 검사: active B 화면에서 전기 branch, 바람 motif, 플레이어 aura가 보이며 danger line·적 탄환·HUD를 가리지 않음

## 남은 Gate

- 390×844, 430×932 portrait visual matrix
- 실제 기기 FPS, hitch, thermal, memory, haptic
- 10분 node·texture recovery soak
- Reduce Motion, photosensitivity safe, Color Assist, VoiceOver 수동 검사
- 최소 5명 A/B 블라인드 선호와 공격 속성 오인율
- 생성물 이용 조건, 참조 권리, side-by-side 비유사성, 상표 검토

따라서 Stage 6의 제한된 로컬 디자인 prototype은 `Go`, Release Readiness는 `Revise`다.
