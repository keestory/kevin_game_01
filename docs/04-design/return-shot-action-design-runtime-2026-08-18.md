# Return Shot Action Design Runtime — 2026-08-18

## 판정

- 단계: Stage 6 Implementation
- 로컬 Visual MVP Gate: `Go`
- 실제 사용자·실기기 접근성·성능 Gate: `Revise`
- 공개 GitHub/App Store Gate: kit 권리 확인 전 `Stop`

## 적용 결과

기존 구조를 재작성하지 않고 `BrickBreakerDesignAdapter` 위에 제품용 `GamePalette`, `GameSpacing`, `GameRadius`, `GameMotion` bridge를 추가했다. 홈, 설정, 게임 HUD, SpriteKit 게임판, 일시정지, 결과가 한 디자인 언어를 사용한다. `GameRules`, 점수, 물리, seed, checksum, profile 계약은 변경하지 않았다.

## 추출한 디자인 규칙

1. Canvas는 거의 검은 navy이며 surface 0~3으로 깊이만 만든다. 배경 장식은 gameplay 오브젝트보다 앞서지 않는다.
2. 간격은 4·8·12·16·24·32pt 계열, radius는 brick 4·badge 6·button 10·card 12·panel 16pt를 사용한다.
3. Orange/amber는 핵심 CTA와 record 상태에 집중한다. 상시 glow는 금지하고 공·skill core·짧은 impact에만 제한한다.
4. 플레이 위계는 `공과 위험 신호 → 벽돌 역할 → 짧은 효과 → HUD → 배경`이다.
5. 일반 벽돌은 색+glyph+pattern, prism은 별+HP pips, negative는 minus+red outline, armor는 별도 plate로 중복 전달한다.
6. 번개는 segmented branch, 화염은 fan/ember, 바람은 curved streams, 관통은 straight lance/X cut을 사용한다. explosion·multiball·ice·homing·laser·shield·slow time은 추가하지 않는다.
7. 홈의 시작 CTA와 결과의 재도전 CTA는 첫 viewport에 둔다. 일시정지 후 자동 재개하지 않는다는 문구를 보여준다.
8. iPhone touch 제품은 hover 대신 pressed state, 최소 44pt target, 충분한 텍스트 대비와 Dynamic Type 대응을 검증한다.
9. 375×667과 402×874에서 4칸 skill rail, tutorial feedback, 게임판, pause/result CTA가 잘리지 않아야 한다.
10. imported JSON·TypeScript·reference 이미지는 참고 입력으로만 보존하고 런타임 decode, Xcode resource, SwiftPM source로 사용하지 않는다.

## 시각 QA

- iPhone 17 Pro 402×874: Home→Game→Pause→Resume→Result→Same Seed Retry 통과.
- SE급 375×667: 같은 흐름 통과, 수평 clipping 0, 핵심 CTA 첫 viewport 노출.
- 색 외 신호: brick glyph/pattern, HP/armor pips, 4종 skill icon/label/shape 확인.
- 클릭 명확성: 시작·재도전은 amber fill, pause·설정·공유는 outline/surface 계층으로 구분.
- 게임 캡처에서 HUD와 skill rail은 공·벽돌을 가리지 않았고 tutorial feedback은 플레이 구역 상단에 고정됐다.

## 자동 검증

- SwiftPM: 25/25 성공.
- Xcode iPhone 17 Pro: 단위 26 + UI 2 = 28/28 성공.
- Xcode SE급 UI: 제품 전체 흐름 1/1 성공.
- Debug generic iOS Simulator build 성공.
- 결정론 30/60/120Hz checksum 회귀 성공.

## 남은 위험

- 실제 한국 iPhone 사용자 재미·첫 행동·자발적 3회차·D1/D7 증거는 없다.
- VoiceOver, Switch Control, Increase Contrast, 최대 Dynamic Type, 최소 지원 실기기 10분 성능은 Release 전 추가 검증이 필요하다.
- kit에 LICENSE·NOTICE·상업·수정·재배포 허가가 없어 공개 commit과 App Store 배포는 중단 상태다.
- 사용자 소유 미추적 `AppIcon 2.png`는 asset catalog warning을 내지만 이번 범위에서 삭제하지 않았다.

## 2026-08-19 Action Design Art Layer Revision

오너의 직접 시각 감사에서 앞선 semantic-token 적용은 레퍼런스의 디자인 반영으로 인정되지 않았다. 따라서 위 `로컬 Visual MVP Gate: Go`는 토큰 통합 구현에만 한정하며, 시각 제품 승인은 이 revision의 기준으로 다시 판정한다.

### 실제 런타임 변경

- `GameArtCatalog`가 배경, 벽돌 재질, chrome/energy 공, HUD frame, 번개·화염·바람·관통 VFX를 typed asset으로 로드하고 texture cache와 normalized crop을 제공한다.
- 홈·게임·일시정지·결과는 같은 3층 산업형 세계 배경과 HUD frame을 사용한다.
- 게임 벽돌은 재질 base 위에 기존 glyph·armor·HP·negative·support 정보를 절차형 overlay로 유지해 시각 품질과 규칙 가독성을 동시에 보존한다.
- 패들은 불투명 이미지의 흰 matte를 채택하지 않고 chassis, orange endcap, energy core, blue tick을 절차형으로 렌더한다.
- 공격 VFX는 additive texture와 공격별 고유 형태를 사용하되 공보다 아래에 배치하고 동시에 최대 8개만 유지한다. Reduce Motion에서는 정적이고 짧은 cue로 축소한다.
- 원본 레퍼런스 보드와 반입 kit 이미지는 앱 번들에 포함하지 않았다. 프로젝트 아트는 ImageGen으로 별도 생성했으며 provenance와 SHA-256은 `docs/ASSET_PROVENANCE.md`에 기록했다.

### 최신 화면 QA

- SE급 375×667: Home→Game→Pause→Result→Same Seed Retry 1/1 통과.
- Home: native gradient wordmark, material preview, chrome ball, 절차형 mechanical paddle, 기록 3종과 시작 CTA가 첫 viewport에 노출된다.
- Game: compact HUD와 4-skill rail 아래에 material brick·energy ball·mechanical paddle이 명확히 보이며 수평 clipping 0건이다.
- Pause/Result: CTA가 첫 viewport에 있고 배경·frame·typography가 게임과 같은 시각 언어를 사용한다.
- 공격 showcase: 번개·화염·바람·관통 4/4가 서로 다른 형태로 표시되고 공·벽돌의 핵심 판정을 가리지 않는다.

### 검증 및 Gate

- Xcode unit 28/28, SwiftPM GameRules 25/25, SE 핵심 UI 1/1, 공격별 UI 4/4 성공.
- `git diff --check`, PBX plist lint, Debug Simulator build 성공.
- Stage 6 로컬 구현: `Go`.
- Visual Product Validation: 실제 사용자 5명 인지·재미 및 실기기 접근성·성능 증거가 없어 `Revise`.
- 공개 GitHub/App Store: 참고 kit의 권리 확인 전 `Stop`.
