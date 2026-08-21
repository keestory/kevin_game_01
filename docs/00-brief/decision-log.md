# Decision Log

확인일: 2026-08-10
책임: Product Orchestrator

## D-001 — 기존 앱의 지위

- 결정: 현재 SwiftUI/SpriteKit 앱은 출시 후보가 아니라 문제·해법 가설을 시험하는 `vertical slice`로 분류한다.
- 근거: 자동 테스트와 빌드는 통과했지만 사용자 인터뷰, 사용성 테스트, 실제 퍼널 데이터가 없다.
- 폐기한 대안: 구현 완료를 이유로 Implementation Gate를 사후 승인하는 방식.
- 영향: 추가 기능보다 Brief, 시장 근거, 사용자 검증, 측정 계획을 먼저 보완한다.

## D-002 — 1위 목표와 제품 성공 기준 분리

- 결정: 한국 iPhone 무료 Games 1위는 출시 결과 목표로 유지하되 MVP Gate 기준으로 사용하지 않는다.
- 근거: 순위는 제품 품질뿐 아니라 동시 다운로드, 사전예약, 광고비, 피처링과 경쟁작 출시 시점의 영향을 받는다.
- MVP 성공 기준: 첫 판 시작률, 첫 판 완료율, 첫 세션 재도전율, D1/D7 유지율, 공유율, 무결점 세션.
- 폐기한 대안: 다운로드 순위를 코어 재미의 대리 지표로 사용하는 방식.

## D-003 — 친구 초대 보상

- 결정: 설치·가입을 요구하는 강제 초대 보상은 MVP에서 제외한다.
- 근거: 초대 스팸, 보상 어뷰징, 친구 관계 마찰, 완료 검증을 위한 서버 비용이 코어 가설 검증을 흐린다.
- 허용 범위: 현재는 기록 공유만 제공한다. 같은 시드 도전은 Universal Link와 서버 검증을 설계한 뒤 별도 실험한다.

## D-004 — 보상형 광고

- 결정: 강제 전면 광고는 제외하고, 조기 종료 시 판당 최대 1회의 명시적 선택형 구조만 후보로 둔다.
- 선행 조건: 광고 없이도 첫 세션 재도전율과 D1 Gate를 통과해야 한다.
- 구현 상태: Debug에는 모의 reward callback이 있고 Release에는 실제 SDK 연결 전 CTA가 노출되지 않는다.
- 폐기한 대안: 실패할 때마다 광고를 보게 하거나 광고 시청을 실질적으로 강제하는 방식.

## D-005 — 네이티브 iOS 선택

- 결정: 첫 검증 플랫폼은 한국 iPhone 네이티브 앱으로 유지한다.
- 이유: 60fps 원터치 입력, 햅틱, 오프라인 플레이, App Store 출시 집중이 핵심 경험과 직접 연결된다.
- 대안: 규칙·메시지 검증은 영상 광고와 클릭 프로토타입으로 먼저 수행하고, 설치 전환 검증은 랜딩페이지로 보완한다.

## D-006 — 다음 구현 승인 조건

- 결정: 새로운 성장·수익 기능 구현은 Problem Validation Gate 전까지 동결한다. P0/P1 수정과 검증 도구 작업만 예외로 한다.
- 완료 조건: 핵심 세그먼트 8~15명 인터뷰, 5명 무설명 플레이 테스트, 실제 행동 증거, 반복 패턴 3개, 반증 결과 기록.

## D-007 — 5×7 추상 보드 폐기와 실제 열차 채택

- 결정: 기존 선택기·원형 토큰·5×7 매치 보드는 제품 콘셉트에서 폐기한다. 새 vertical slice는 실제 측면 지하철 1량, 3쌍 미닫이문, 플랫폼, 정차선, 사람 형태 승객을 보여주는 `정차선 제동` 원탭 게임이다.
- 직접 근거: 2026-08-09 사용자 테스트 피드백에서 기존 버전이 재미없고, 그래픽·효과가 부족하며, 하차를 말하면서 실제 열차가 없다는 문제가 제기됐다.
- 에이전트 충돌: Engineering은 검증된 보드 규칙 재사용을 권했지만 UX/Red Team은 보드 자체가 열차 인지와 손맛을 막는다고 판정했다. Product Orchestrator는 직접 사용자 피드백을 우선해 UX안을 채택했다.
- 영향: 5개 역 각각 `접근 → 제동 → 문 개방 → 승하차 → 출발`을 12초 안에 수행한다. 점수가 아니라 `하차 인원/목표`를 전면에 둔다.
- 폐기한 대안: 기존 보드 위에 열차 테두리·파티클만 추가하는 시각적 리스킨.

## D-008 — 광고·친구 설치는 성공 조건이 아님

- 결정: 첫 3판은 무광고, 실패 후 무료 즉시 재시도가 기본이다. Continue는 목표까지 8명 이하 남았을 때만 런당 1회, `다음 역 +12초`를 명시적으로 선택하게 한다.
- 근거: Bus Jam/Bus Out 한국 리뷰에는 초반 광고·난도 절벽 불만이 반복되고, 2026-08-09 한국 최고매출 #6 Royal Match는 광고 없이 IAP로 운영된다.
- 친구 기능: 설치·가입 현상금은 어뷰징·스팸·신뢰 비용 때문에 제외하고 결과 공유부터 검증한다.
- 미확인: 광고 유무가 유지·LTV에 미치는 영향, 한국 CPI/eCPM/LTV.

## D-009 — 열차 타이밍 게임 중단과 endless 기록형 재탐색

- 결정: 정차선 제동, 목적지 문 선택, 목표 인원 문닫기를 포함한 열차 게임 방향을 중단한다. 현재 앱과 `rev4` 명세는 학습 증거로 보존하지만 새 제품 승인 근거로 사용하지 않는다.
- 직접 근거: 오너의 반복 플레이에서 입력 빈도, 상호작용, 조작 숙련, 개인 기록 추격이 부족해 재미가 없다는 피드백이 계속됐다. 열차 그래픽을 강화해도 코어 문제가 해소되지 않았다.
- 새 단일 후보: `연쇄파괴: 리턴 샷`. continuous paddle로 반사각을 만들고 약점 연쇄붕괴·endless 높이·점수·콤보·PB ghost를 추격한다.
- 시장 근거: 2026-08-10 한국 무료 Games의 Smash Fest·Block Blast와 글로벌 물리 파괴 게임은 acquisition 가설만 지지한다. 한국 iOS 유지·매출·무료 1위 가능성은 미확인이다.
- 폐기한 대안: Encircle과 핵심 규칙이 겹치는 Looplight, incumbent와 콘텐츠 비용이 큰 endless runner, 음악 권리·저지연 QA 비용이 큰 rhythm.
- 에이전트 충돌: Market은 현재 매출 근거 부재를 경고했고 UX는 active-paddle를 추천했으며 Engineering은 deterministic collision 없이는 공정성을 보장할 수 없다고 판정했다. Product Orchestrator는 2일 collision spike와 5일 no-ad graybox만 승인한다.
- Gate: 사용자 5명 중 4명의 5초 이해, active-touch 중앙값 60% 이상, Run 3 기록 중앙값이 Run 1보다 20% 이상 상승, 3/5 자발적 재시도, deterministic replay와 공 관통 0건을 모두 요구한다.
- Stop: 위 Gate 실패, 3/5 이상이 `그냥 벽돌깨기`로만 인지, 불공정 물리 1건, 지원 하한 기기 성능 실패 시 그래픽·수익화·출시 투자를 중단한다.
- 상세 근거: [Endless Score Pivot — 2026-08-10](../01-research/endless-score-pivot-2026-08-10.md).

## D-010 — Return Shot의 속성 LINK·프리즘·마이너스 구조 채택

- 결정: 사용자가 제안한 콤보, 색·무늬·마크 연속 보너스, 일시 파워, 다중 타격 보너스 벽돌, 직접 적중 감점과 간접 낙하 제거를 `Return Shot` graybox의 검증 범위로 채택한다.
- 단순성 보호: 세 기능을 별도 팝업으로 동시에 설명하지 않고 구조의 높이로 `LINK → 프리즘 → 마이너스 지지 제거` 순으로 노출한다.
- 고유 재미 가설: 능동 반사로 속성 경로를 잇는 조작, 프리즘 완파와 빠른 붕괴 사이의 투자 선택, 마이너스 벽돌을 직접 치지 않고 구조로 제거하는 위험 선택의 결합이다.
- 에이전트 충돌: Market/Red Team은 세 시스템 동시 구현을 Stop하고 마이너스 지지 제거만 먼저 검증하라고 권고했다. UX는 세 판단의 결합이 차별화라고 봤고 Engineering은 규칙 고정 뒤 deterministic spike만 허용했다. Product Orchestrator는 사용자의 명시 요청을 반영하되 물리적 높이 순차 노출과 hard Stop 조건으로 복잡성 위험을 제한한다.
- 비차별 요소: 연속 적중 파워와 multi-hit 벽돌 각각은 선행 게임 문법이므로 단독 차별점으로 주장하지 않는다.
- Gate: [Return Shot ProductSpec rev1](../product-specs/return-shot-chain.product-spec.md)의 RS-AC-1~12를 적용한다.

## D-011 — Visual Builder 기본안 A 채택

- 결정: 2026-08-17 ImageGen+Vision 반복 결과, `Precision Neon`을 기본 시각안으로 채택하고 `Impact Pop`을 `-visualB` challenger로 보존한다.
- 근거: 동일 seed·규칙에서 A의 중립 지지선이 벽돌의 색·무늬·마크보다 앞서지 않았고, B의 amber 지지선은 붕괴 에너지는 크지만 구조가 복잡하게 보였다. iPhone 17 Pro·17e·SE 375×667 실캡처에서 A는 HUD·벽돌·튜토리얼·패들 clipping 없이 통과했다.
- 구현 검증: SwiftPM 12/12, Xcode unit 12/12, XCUITest 1/1. 자동 흐름은 홈→시작→드래그→일시정지→재개→결과→같은 seed 재도전이다. 모든 실제 지지선을 표시하고 공은 안내 band 밖의 top wall 아래에 제한한다.
- 한계: 이 결정은 휴리스틱 시각 QA이며 사용자 A/B나 retention 증거가 아니다. `Revise-Go`로만 판정하고 실제 5명 mastery Gate 전 본개발·수익화·출시 승인을 금지한다.
- 상세 보고: [Return Shot Visual Builder Report — 2026-08-17](../04-design/return-shot-visual-builder-report-2026-08-17.md).

## D-012 — 네 공격을 단일 입력 스킬 코어로 제한

- 결정: 번개·화염·바람·관통은 모두 구현하되 별도 버튼, 선택 모달, 영구 인벤토리, 네 공격의 상시 중첩은 만들지 않는다. 구조마다 일반 벽돌 한 개에 코어를 넣고 직접 파괴한 순간 해당 공격이 한 번 발동하며, 공격별 run 레벨만 Lv1~3으로 누적한다.
- 사용자 근거: 오너가 공격 아이템을 벽돌 안에 배치하고 각 공격이 레벨에 따라 강화되며 구조 진행에 따라 방어력도 올라가는 방향을 명시했다.
- 시장 근거: 2026-08-18 한국 무료 Games에는 `Royal Smash` #18과 `Block Blast` #14가 관측됐지만 직접군은 매출 Top 25에 없었다. `PunBall`, `Bricks Ball Crusher`는 스킬 성장 수요의 선행 사례인 동시에 과도한 시스템·HP·운영비 위험의 반증이다.
- 에이전트 충돌: Market/Red Team은 4종 전체를 Stop하고 관통 1종만 시험하라고 권고했고, UX는 번개/화염 2종 단일 슬롯만 승인했다. Engineering은 별도 armor와 bounded deterministic wave라면 구현 가능하다고 판정했다.
- Orchestrator 통합: 사용자의 명시 범위는 보존하되 네 공격을 동시에 지속시키지 않고 코어 파괴 시 1회 bounded wave로 축소한다. 방어력은 core HP가 아닌 별도 armor 0~2만 허용해 prism 3HP 계약과 무광고 해결 가능성을 지킨다.
- 공정성: 같은 seed는 carrier·공격 종류·target order가 동일하다. shockwave·낙하·다른 공격으로 제거한 carrier는 획득되지 않고, 공격은 negative·carrier를 대상으로 삼거나 LINK·다른 코어를 발동하지 않는다.
- Gate: ProductSpec rev3의 AC-13~17, 기존 결정론·시각·사용자 Gate를 모두 통과해야 한다. 실제 5명 테스트 전 판정은 `Revise-Go`이며 한국 무료 1위·retention·수익성은 `Unknown`이다.
- Stop: 일반 벽돌 3회 초과 반복타, active-touch 60% 미만, 사용자 2/5 이상의 LINK/core 혼동, attack 재귀·negative 오판 1건, SE 화면 가림 또는 성능 P1이 발생하면 4종을 2종 이하로 축소한다.

## D-013 — Brick Breaker Kit은 Swift 네이티브 어댑터로만 연결

- 결정일: 2026-08-18 KST
- 결정: 사용자가 전달한 `CODEX_START_PROMPT.md`는 비권위 구현 입력으로 검토한다. 기존 SwiftUI·SpriteKit·GameRules·AppModel 구조와 Return Shot ProductSpec rev3를 보존하고, Debug launch argument `-designGallery`에서만 열리는 SwiftUI Gallery와 typed Swift token mapping을 추가한다.
- 채택: semantic palette, spacing, radius, Dynamic Type, 44pt control, Reduce Motion·Photosensitivity Safe·Color Assist의 Gallery-local preview, 현재 승인된 번개·화염·바람·관통 4종의 one-shot 표현 preview.
- 수정 채택: source kit의 `fire → flame`, `electric → lightning`, `piercing → pierce`를 표현 이름으로만 연결한다. kit에 없는 wind는 현행 제품색을 `provisional adapter extension`으로 명시한다.
- 폐기: TypeScript/Vite/Phaser 전환, 런타임 JSON decode, boss HUD, explosion·multiball·ice·homing·laser·shield·slow time, 8-ball stress, desktop/keyboard 요구, effect loop·gameplay intensity 조정. 이 항목은 현재 단일 공·120Hz 결정론·승인된 네 공격 계약을 바꾸므로 Stage 4 재승인 없이는 구현하지 않는다.
- 구조 경계: Gallery는 `AppRoute`, GameRules, GameScene, profile, persistence, score, seed, checksum을 호출하거나 변경하지 않는다. imported JSON/TS/PNG는 Xcode·SwiftPM resource나 source input으로 추가하지 않는다.
- 권리: kit의 LICENSE·NOTICE·상업/수정/재배포 허가가 없으므로 로컬 Debug 검토는 진행하되 공개 저장소 commit·상용 배포는 권리 확인 전 `Stop`이다.
- 상세 계약: [Native Design Adapter](../04-design/native-design-adapter.md).

## D-014 — 승인된 어댑터 문법을 실제 Return Shot 제품에 적용

- 결정일: 2026-08-18 KST
- 결정: Debug Gallery에서 검토한 semantic palette·spacing·radius·motion과 현재 네 공격의 표현 문법을 일반 제품 흐름에 적용한다. SwiftUI·SpriteKit·AppModel·순수 GameRules 경계는 보존한다.
- 적용 범위: 홈, 설정, 게임 HUD, SpriteKit 배경·벽돌·공·패들·공격 효과, 일시정지, 결과. imported JSON·TypeScript·reference PNG는 런타임 resource가 아니다.
- 시각 위계: 공과 위협 신호가 최우선이며, 벽돌 역할과 공격은 색뿐 아니라 glyph·pattern·shape로 구분한다. glow는 공·core·짧은 impact에 제한한다.
- 검증: iPhone 17 Pro 402×874 전체 UI 흐름과 SE급 375×667 전체 UI 흐름을 실제 캡처했다. SwiftPM 25/25, Xcode 단위 26 + UI 2 = 28/28을 통과했다.
- 비변경: 점수, 물리, seed, checksum, 네 공격의 권위 규칙, profile은 변경하지 않았다.
- Gate: 로컬 Stage 6 Visual MVP는 `Go`. 실제 사용자 재미·접근성·성능 검증은 `Revise`; kit 권리 확인 전 공개 GitHub/App Store는 `Stop`.
- 상세 보고: [Return Shot Action Design Runtime](../04-design/return-shot-action-design-runtime-2026-08-18.md).

## D-015 — 토큰 적용 판정을 철회하고 Action Design 아트 레이어로 교체

- 결정일: 2026-08-19 KST
- 오너 판정: D-014의 semantic color·spacing 적용만으로는 제공된 `BRICK BREAKER ACTION DESIGN SYSTEM`의 디자인이 반영됐다고 볼 수 없다. 따라서 D-014의 `Visual MVP Go`는 시각 제품 승인 근거로 사용하지 않는다.
- 결정: 기존 SwiftUI·SpriteKit·순수 `GameRules` 구조는 보존하면서, 자체 생성한 배경·벽돌 재질·에너지 공·HUD frame·4종 공격 VFX와 절차형 기계 패들을 실제 Home/Game/Pause/Result 렌더 경로에 연결한다.
- 표현 계약: 벽돌은 bevel·specular·durability overlay, 공은 고대비 chrome/energy core, 패들은 chassis·endcap·energy core, 배경은 foreground frame·mid structure·deep vanishing point의 3층 깊이를 사용한다. 번개·화염·바람·관통은 서로 다른 silhouette와 motion grammar를 사용하며, 공보다 낮은 z-order와 최대 8개 transient cap을 지킨다.
- 비변경: 점수, 충돌, combo, LINK, armor, attack target order, seed, checksum, profile 및 `GameRules`는 변경하지 않는다.
- 검증: Xcode unit 28/28, SwiftPM 25/25, SE급 Home→Game→Pause→Result→Same Seed Retry UI 1/1, 공격별 showcase UI 4/4를 통과했다. 최신 SE 캡처에서 수평 clipping과 흰 matte 배경은 0건이다.
- Gate: 로컬 Stage 6 구현은 `Go`. 5명 무설명 인지·재미, 최소 지원 실기기 10분 60fps/열, VoiceOver·Switch Control·Increase Contrast·최대 Dynamic Type가 남아 Visual Product Validation은 `Revise`. 참고 kit의 권리 확인 전 공개 GitHub/App Store는 `Stop`이다.
- 상세 보고: [Return Shot Action Design Runtime](../04-design/return-shot-action-design-runtime-2026-08-18.md#2026-08-19-action-design-art-layer-revision).

## D-016 — Run LEVEL과 bounded MAX OVERDRIVE 채택

- 결정일: 2026-08-19 KST
- 사용자 근거: 오너가 더 역동적인 효과, 단계별 난이도, 아이템을 다시 획득할수록 강해지는 성장을 요청했다.
- 결정: 영구 성장·무한 공격 등급을 추가하지 않고 현재 run의 구조 번호를 `LEVEL`로 노출한다. Level 1은 LINK와 코어만, Level 2는 프리즘, Level 3은 마이너스, Level 4는 armor를 순서대로 소개한다. armor는 Level 4~6에서 1, Level 7 이상에서 2로 고정하며 공 속도는 518pt/s를 상한으로 둔다.
- 아이템 성장: 번개·화염·바람·관통은 기존 Lv1~3 계약을 유지한다. 이미 Lv3인 같은 코어를 직접 획득하면 rank를 올리지 않고 `MAX OVERDRIVE`를 발동해 최초 대상과 동일한 stable ID만 정확히 15 authoritative tick 뒤 한 번 더 공격한다. 사라진 대상을 대체 표적으로 바꾸지 않으며 primary와 echo를 합쳐 combo 증가는 최대 1이다. 관통은 +3 뒤 +3을 지급하되 보유량은 6으로 제한한다.
- 연출: Level 전환 outline, 벽돌 hit spark, MAX 2차 pulse를 추가한다. 모든 VFX는 공보다 아래에 두고 Reduce Motion에서는 이동·확대 대신 짧은 outline으로 축소한다.
- 시장·Red Team 판단: 2026-08-19 한국 iPhone 무료·매출 상위권에 직접 brick-breaker 증거가 없어 progression은 retention 가설로만 취급한다. `PunBall`류의 성장 정체·HP 급증 사례를 반증으로 보고 core HP·영구 meta·유료 power는 추가하지 않는다.
- Conflict: Market은 Lv3 중복을 같은 효과 즉시 재발동으로 제한하자고 했고 UX는 강화 체감을 위해 15-tick echo를 제안했다. Orchestrator는 결정론·target cap·combo cap을 보존하는 bounded echo를 실험안으로 채택했다.
- 검증: SwiftPM 32/32, 10,000 seed 구조 결정론·무아이템 clearability, 30/60/120Hz checksum, 15-tick echo·same-ID·no-retarget·pierce cap 테스트를 통과했다. 실제 사용자 재미와 D1/D7 개선은 미확인이다.
- Gate: 로컬 Stage 6 구현은 `Go`. 사용자 5명 중 4명의 Level/코어 성장 이해, active touch 중앙값 60% 이상, 무광고 clear와 실기기 성능을 확인하기 전 Product Validation은 `Revise`다.

## D-017 — Descent Breaker를 Return Shot 대비 비교 slice로 채택

- 결정일: 2026-08-19 KST
- 사용자 근거: 오너가 위에서 오브젝트와 불·전기·관통·바람·폭발 코어가 계속 내려오고, 하단에서 이를 파괴·수집하는 새 디자인 보드를 직접 제작해 제안했다.
- 결정: 다음 60초 비교 vertical slice는 `Descent Breaker`로 구현한다. Return Shot은 동일 참가자 A/B baseline으로 보존하고 전면 폐기하지 않는다.
- 고유 재미: 단순 자동 사격이 아니라 위험선 직전 오브젝트를 먼저 막을지, 떨어지는 공격 코어를 받으러 lane을 바꿀지의 실시간 우선순위 선택을 핵심으로 한다.
- 구조 경계: 기존 `AttackItemKind`, `ReturnShotState`, `GameRules`, `GameScene`은 보존한다. 별도 Descent state/rules/scene/snapshot을 추가해 seed·checksum·테스트를 분리한다.
- MVP 축소: 일반·강화·스파이크·드론·코어의 수직 lane 패턴만 허용한다. 미니보스, 적 탄환, 회전·지그재그, 수동 스킬 버튼, cooldown, 영구 meta, 광고·결제는 제외한다.
- 시장 근거: 2026-08-19 한국 iPhone Games 무료·매출 Top 25에는 직접 인접작이 없지만 Ball Blast 5천만+ Android, Galaxy Attack·1945 1억+ Android와 한국 iOS 평가 축적은 낙하 파괴·전투 중 아이템 강화의 대중성 proxy다. 경쟁작 D1/D7과 한국 1위 가능성은 미확인이다.
- Conflict: Market/UX는 3초 이해도와 피드백 밀도 때문에 Descent를 선택했고 Engineering은 기존 ProductSpec과의 P0 충돌을 경고했다. Orchestrator는 전면 교체 대신 별도 모델의 비교 slice만 승인했다.
- Gate: Stage 4 Solution Definition은 `Conditional Go`; 실제 5명 A/B, 10,000 seed 공정성, 30/60/120Hz 결정론, 작은 iPhone 시각·성능 전에는 제품 pivot과 출시를 `Stop`한다.
- 상세 계약: [Descent Breaker ProductSpec rev1](../product-specs/descent-breaker.product-spec.md).

## D-018 — 조작기형 bar 제거와 출격 전 3기체 loadout 채택

- 결정일: 2026-08-20 KST
- 사용자 근거: 오너가 하단 reactor bar를 제거하고 비행기만 보이게 하며, 게임 전에 캐릭터를 고르고 기존 투명 에셋의 서로 다른 미사일을 발사하도록 명시했다.
- 결정: field 전체 drag 입력은 유지하되 조작기처럼 오해되는 하단 bar node를 제거한다. reactor 3HP는 상단 HUD에서만 유지한다. 홈의 Descent CTA는 preflight로 연결하고 `Swift S-1`, `Hammer H-2`, `Trident T-3` 중 하나를 선택한 뒤 별도 출격 CTA로 run을 시작한다.
- 전투 계약: Swift는 22 ticks마다 1×damage 1 pulse, Hammer는 44 ticks마다 1×damage 2 lance, Trident는 66 ticks마다 선택 lane을 포함한 3-lane salvo를 damage 1씩 발사한다. 총 이론 DPS는 5.45로 같고 기체별 HP·속도·pickup·score 보정은 없다.
- 결정론: 선택 기체와 missile kind를 권위 state·projectile·checksum에 포함한다. Trident는 edge에서도 세 고유 lane, cap 여유 부족 시 atomic skip, 관통은 volley당 1회·lead projectile만 적용한다. 같은 seed 재시도는 같은 기체를 유지하고 run 중 변경은 금지한다.
- 시각·접근성: 사용자가 제공한 `DB_PlayerAttacks` 투명 시트의 소·중·대 기체와 pulse·lance·salvo를 typed crop으로 연결한다. 각 선택 카드는 독립 44pt 이상 Button과 선택 trait/value를 가지며 기체와 원소 스킬은 명칭·형태·HUD 역할을 분리한다.
- Conflict: Market/Red Team은 첫 선택 부담을 줄이기 위한 2기체 A/B를 권고했다. Product Orchestrator는 최신 사용자 요구를 우선해 3기체 challenger를 구현하되 5명 중 4명의 5초 내 선택·출격, 2개 이상 패턴 설명, 100-seed score 중앙값 편차 8% 이하를 통과하지 못하면 2기체로 축소한다.
- 구현 증거: SwiftPM 52/52와 375×667 UI `home → 기체 선택 → Hammer → play → pause → result → retry` 1/1을 통과했다. 실제 5명 선택 이해, 100-seed 기체별 score 편차, 실기기 성능은 미확인이다.
- Gate: 로컬 Stage 6 구현은 `Go`; Product Validation은 `Revise`; 에셋 권리·실기기 접근성·성능·출시 점검 전 App Store Release는 `Stop`이다.
- 상세 계약: [Descent Breaker ProductSpec rev2](../product-specs/descent-breaker.product-spec.md).

## D-019 — 30초 레드라인 Choice Arena 채택

- 결정일: 2026-08-20 KST
- 사용자 근거: 오너가 다음 단일 스프린트로 `Choice Arena` 진행을 명시했다.
- 결정: 60초 run의 authoritative tick 3600에서 한 번만 `안정 비행`과 `레드라인`을 고르게 한다. 그 tick의 전투 transaction과 finish를 먼저 처리하며, 선택 중에는 simulation과 제한시간을 완전히 정지한다.
- 레드라인 계약: 선택 다음 tick부터 object fall·상대 충돌 delta +18%, 기본 미사일 직접 파괴 base+combo 점수 +35%. Danger Save, 스킬 damage·score, drop, 기체 loadout, HP는 불변이다. 안정 비행은 무변경이다.
- 제품 이유: generic 3-skill draft 선택은 현재 고유 루프인 `core 파괴 → 떨어진 원소를 직접 받으러 이동`을 약화하고 원소 성장과 중복된다. Choice Arena는 기존 원소 시스템과 분리된 기록 위험 선택으로 제한한다.
- 에이전트 Conflict: Market/Strategy는 로그라이크형 3-skill 선택을 획득·반복 후보로 제안했다. UX/Planning은 선택 피로와 drop 루프 훼손을 반박하고 `안정 vs 기록 위험` 2카드만 제안했다. Engineering/QA는 fixed-tick freeze·checksum·다음 tick 적용 계약을 요구했다. Product Orchestrator는 UX의 bounded 2카드안을 채택했다.
- 시장 근거: 2026-08-20 한국 iPhone 무료·매출 Games 상위 25에는 직접 동형 사례가 없었다. Archero·Survivor.io류는 run 중 선택의 선행 사례지만 Descent의 유지율이나 한국 무료 1위를 증명하지 않으므로 Choice Arena는 retention 가설로만 취급한다.
- 검증: SwiftPM 58/58에서 exact tick/order/freeze/idempotence, 118% 속도, 직접탄 135% 점수, Danger·skill 불변, 3기체·5스킬·30/60/120Hz·checksum을 검증했다. 화면·사용자 Gate는 별도다.
- Gate: 로컬 Stage 6 구현은 Xcode UI flow 통과 시 `Go`; 5명 중 4명의 5초 이해, 레드라인 선택률 20~80%, 특정 기체 우위 8% 이하 전 Product Validation은 `Revise`다.
- 상세 계약: [Descent Breaker ProductSpec rev3](../product-specs/descent-breaker.product-spec.md#choice-arena).

## D-020 — Choice Arena는 로컬 A/B로 검증하고 PB Pace와 분리

- 결정일: 2026-08-20 KST
- 결정: Choice Arena의 제품 채택은 코드 완성만으로 확정하지 않는다. 외부 분석 SDK 없이 Debug research build의 `noArena`와 `choiceArena` 두 variant를 동일 seed·기체로 비교하는 10명 counterbalanced A/B를 먼저 수행한다.
- Primary: 참가자 단위 자발적 3회차 완료, `ComparableScore = score - redline bonus`의 Run 1→3 20% 상승, active-touch 비열등성이다. 총점 평균은 레드라인 자체 보너스가 섞이므로 Primary로 사용하지 않는다.
- 실험 무결성: research run은 fresh PB를 사용하고 기존 저장 PB를 읽거나 덮어쓰지 않는다. 30초 현재 점수와 60초 최종 BEST를 `PB까지`로 비교하지 않으며 PB Pace Rival은 동일 시점 trace가 준비된 후 별도 실험으로만 진행한다.
- 계측·개인정보: run 시작·입력·첫 파괴·첫 drop·선택·입력 요약·종료·재시도만 1MB/100-run 상한의 로컬 JSONL로 기록한다. raw touch 좌표, 이름, 연락처, Apple ID, 광고 ID, 정확한 접근성 설정, 네트워크 전송은 금지한다. 시작·선택·종료 때 upsert해 강제 종료로 terminal이 누락된 run도 DQ에서 식별한다.
- Gate: 구현·자동 QA는 `Go`; 실제 10명 A/B는 미실행이므로 Product Validation은 `Revise`. 필수 event 중복·누락, A에서 Choice 이벤트, variant 간 seed·ship 불일치, carried-touch 오선택은 한 건이라도 실험 무효 또는 Stop이다.
- 상세 계획: [Choice Arena Local Research Analytics Plan](../03-product/analytics-plan.md).

## D-021 — Choice Arena 연구 데이터는 fail-closed console에서만 판정

- 결정일: 2026-08-20 KST
- 결정: P01–P10 배정은 P01–P05 A→B, P06–P10 B→A로 코드에서 강제한다. 참가자·order·variant 조합이 다르면 logger를 켜지 않고 게임 시작 전에 차단한다.
- 원자료 보존: local JSONL의 손상·future-schema line, read 오류, 100-run/1MB 상한은 hard DQ 오류다. 정상 행만 남겨 재작성하거나 오래된 run을 자동 삭제하지 않는다. 저장 실패가 발생한 run은 무효이며 다음 연구 run을 시작하지 않는다.
- Primary 계약: 자발적 3회차는 필수 run 2 뒤 `optionalRetryWindowOpened(60000)`가 있고 동일 seed·ship 재시도와 run 3 terminal이 있을 때만 1이다. Run1→Run3 20% 상승은 10명 ITT 분모로 유지하며 미시작·미완료는 0이다.
- 운영 화면: DEBUG `Research Console`에서 DQ→수집 진행→Primary→P01–P10 순으로 확인하고, 유효할 때만 participant-variant summary CSV를 내보낸다. 삭제는 확인 modal 뒤 전체 원자료를 제거한다.
- 개인정보: 이름·연락처·raw 좌표·기기 ID는 앱에 기록하지 않는다. 평정·comprehension·input mode는 별도 비식별 facilitator CSV에만 둔다.
- Gate: 계측·집계·로컬 운영 준비는 `Go`. 실제 10명 연구가 0명이므로 Choice Arena Product Validation은 `Revise`, 공개 출시와 성과 주장은 `Stop`이다.
- 실행 절차: [Choice Arena Research Runbook](../07-operations/choice-arena-research-runbook.md).

## D-022 — Persistent Effects v1.1은 Swift 네이티브 계약으로 제한 병합

- 결정일: 2026-08-20 KST
- 사용자 근거: 오너가 `descent-breaker-persistent-effects-patch-v1.1`을 기존 프로젝트에 검토 후 적용·병합하도록 명시했다.
- 결정: 원본 TypeScript·Vite 구조와 90초·7-lane 수치를 덮어쓰지 않는다. 현재 60초·5-lane·3기체·Choice Arena·120Hz 결정론을 유지하면서 `pickup combat 0 → run-local L0…L3 loadout 갱신 → volley별 immutable snapshot → projectile impact에서 persistent effect` 계약만 Swift로 번역한다.
- 효과 계약: 화염은 동일 stable ID delayed echo, 전기는 stable secondary chain, 관통은 새 lead projectile에만 3/5/7 hit capacity, 바람은 충돌 반경 안 오브젝트를 위로 이동, 폭발은 첫 impact의 bounded radial damage다. 기존 projectile 비소급, 재귀 drop 0, L3 중복은 `MAX` 표시를 강제한다.
- 에이전트 Conflict: UX는 자동전투처럼 보일 위험 때문에 시각 표현만 채택하자고 제안했다. Market/Strategy는 pickup 무피해·immutable snapshot을 유지하면 조건부 채택 가능하다고 판단했다. Product Orchestrator는 사용자의 명시적 병합 요청과 직접조작 보존 조건을 우선해 bounded native core를 채택하되, 사용자 연구 전 retention 개선 주장은 금지한다.
- 실험 무결성: 실제 P01–P10 참가자 연구는 아직 0명이므로 오염된 실험 데이터는 없다. A/B 양쪽을 `descent-rev4-persistent-effects-v1.1-native-r1`로 고정하고 이전 rules version의 run을 같은 판정에 혼합하지 않는다.
- 권리: patch 30/30 manifest hash는 일치했으나 LICENSE/NOTICE와 상업·수정·재배포 허가는 없다. 로컬 네이티브 적용은 진행하지만 원본 파일·파생 exact visual의 공개 GitHub 게시와 App Store Release는 권리 확인 전 Stop이다.
- 검증: SwiftPM 61/61, Debug·Release generic iOS Simulator 앱 전체 빌드, iPhone 17 Pro Simulator Xcode unit·asset·research tests 88/88, 핵심 UI flow 2/2 통과. pickup 이후 효과 visual, 실기기 접근성·10분 성능, 5명 이해·active-touch·재도전은 미검증이다.
- 상세: [Descent Breaker ProductSpec rev4](../product-specs/descent-breaker.product-spec.md#drop-and-persistent-effects), [Patch import record](../05-engineering/descent-persistent-effects-patch-v1.1-import-2026-08-20.md).

## D-023 — BREAK FLOW / COMBO FRENZY를 Revision 5 공통 core로 채택

- 결정일: 2026-08-20 KST
- 오너 결정: 이번 단일 스프린트는 60초 이후 시간을 늘리는 기능이 아니라, 60초 안의 직접 파괴 연쇄가 짧은 frenzy를 만들고 기록 상승으로 이어지는지 검증한다.
- 규칙 계약: 직접 projectile 파괴만 192 ticks 이내 8-chain을 만든다. 8번째 파괴의 다음 authoritative tick부터 360 ticks frenzy가 켜지고, 활성 중 직접 projectile hit마다 종료를 `current tick+360`으로 갱신한다. frenzy 중 직접 파괴의 기존 base+combo points에 +20%를 가산하며 레드라인 +35%와 곱하지 않는다.
- 불변 계약: projectile·skill damage, persistent effect, drop, spawn plan·속도, reactor HP, Danger Save는 바꾸지 않는다. 120Hz fixed tick과 30/60/120Hz replay·checksum 동일성을 유지한다.
- 실험 무결성: Choice Arena P01–P10 실제 데이터는 0명이므로 폐기할 사용자 표본은 없다. 앞으로 A/B 양쪽은 동일한 `rulesVersion = descent-rev5-break-flow-frenzy-r1`을 공통 core로 사용하고 Revision 4 및 다른 rules version의 envelope를 같은 집계에 혼합하지 않는다. 이 변경 뒤 A/B는 여전히 Arena 유무만 비교하므로 BREAK FLOW 자체 효과를 인과적으로 추정하지 않는다.
- 대체 관계: D-022의 persistent-effect·권리·Revision 4 실행 증거는 보존하되, D-022의 A/B rulesVersion 고정 결정만 D-023이 Revision 5로 대체한다.
- 최소 KPI: 5명 방향성 연구에서 active-touch 중앙값 ≥60%, 자발적 3회차 완료 ≥3/5, `score_run3 ≥ 1.20 × score_run1` 충족 ≥3/5다. 같은 seed·ship·choice의 no-input reference score는 active reference의 75% 이하여야 하고, `frenzy_bonus_score / score`는 20% 이하를 권고 상한으로 둔다.
- 시장·성장 판단: 2026-08-20 확인한 [Apple 한국 iPhone 무료 Games](https://apps.apple.com/kr/iphone/charts/6014?chart=top-free)와 [Apple 한국 Games 최고매출 RSS](https://itunes.apple.com/kr/rss/topgrossingapplications/limit=100/genre=6014/json), [총잡이 고양이](https://apps.apple.com/kr/app/%EC%B4%9D%EC%9E%A1%EC%9D%B4-%EA%B3%A0%EC%96%91%EC%9D%B4-%EB%B0%A9%EC%B9%98%ED%98%95-%ED%82%A4%EC%9A%B0%EA%B8%B0/id6764201639)·[Metal Slug Rush](https://apps.apple.com/kr/app/metal-slug-rush/id6775727338) 같은 1차 store 자료는 파괴 crescendo·방치·survivor·meta의 존재를 보여줄 뿐, 이 8-chain cadence가 Descent의 체류·D1/D7·한국 무료 1위를 높인다는 직접 증거는 아니다. 따라서 체류 상승은 사용자 연구 전 **내부 가설/미검증**으로 기록한다.
- 대안 판정: `60초 기록 확정 → +15초 checkpoint`는 체류시간을 직접 늘릴 수 있으나 run length, 60초 기록, 자발적 3회차 분모를 동시에 바꿔 이번 단일변수 검증을 오염시키므로 **Defer**한다. 영구 meta power는 core 재미를 가리고 경제·콘텐츠·밸런스 비용을 추가하므로 이번 vertical slice에서 **Reject**한다.
- Stop: active-touch <60%, 자발적 3회차 <3/5, Run1→Run3 +20% 달성 <3/5, no-input score > active reference의 75%, frenzy score share >20%, 기체 공정성 편차 >8%, 또는 8-chain·192/360-tick·next-tick·30/60/120Hz 결정론 오류 1건이면 기능 확장과 사용자 연구를 중단하고 규칙 범위를 축소한다.
- Gate(2026-08-21 갱신): Stage 6 Implementation은 권위 core·Scene/HUD·schema 2 terminal 계측과 자동시험 기준 `Go`; BF01–BF05 배정·100-seed agency reference·5명 실험이 남아 Data/Problem Validation은 `Revise`; 실험 전 retention 향상 주장은 `Stop`; 실제 D1/D7와 한국 무료 1위 가능성은 `미확인`이다.
- 상세: [Descent Breaker ProductSpec rev5](../product-specs/descent-breaker.product-spec.md#break-flow--combo-frenzy--revision-5-delta), [Choice Arena Local Research Analytics Plan](../03-product/analytics-plan.md).

## D-024 — Ranked Endless를 Clean/Assisted 분리 로컬 vertical slice로 채택

- 결정일: 2026-08-21 KST
- 사용자 근거: 오너는 챕터로 끊지 않고 점수·레벨로 1위를 겨루는 구조를 요청했고, 광고 부활·추가 목숨·유료 부스터는 허용했다.
- 결정: 일반 Descent 진입은 60초 결과 없이 7,200 tick마다 레벨이 이어지는 `Ranked Endless`로 연결한다. Revision 5 Daily 60 / Choice Arena 연구는 연구·레거시 테스트 인자에서만 유지해 실험 오염을 막는다.
- 경쟁 무결성: 무보조 run만 Clean으로 시작한다. 부스터 장착, 광고 부활 또는 추가 목숨 사용은 같은 Run ID를 영구 Assisted로 전환한다. 첫 Clean fatal checkpoint만 in-process replay 일치 후 Local Top 10에 들어가며 Assisted score는 별도 PB만 갱신한다.
- 수익화 경계: DEBUG mock 보상 광고와 로컬 extra-life/booster만 구현했다. Release에는 보상 광고를 unavailable로 두며 StoreKit, paid ledger, 실제 ad SDK·SSV와 공개 구매 UI는 구현하지 않았다.
- 에이전트 Conflict: Strategy/Market은 긴 run의 시간 우위와 pay-to-rank 오해를 경고했고 Product/UX는 중단 없는 기록 추격을 우선했다. Engineering/QA는 서버 검증 없는 public rank를 반대했다. Orchestrator는 로컬 Clean Top 10 + Assisted PB만 Go하고 세계/시즌 랭킹과 실수익화를 Stop했다.
- 검증: SwiftPM 79/79, Debug generic Simulator build, iPhone SE Ranked preflight/Assisted/Level 2 UI flow를 통과했고 live run에서 Level 3까지 무중단 진행을 관측했다. 10분 autoplay, 실기기, 100-seed 3기체 공정성, 10명 사용자 Gate는 미실행이다.
- Gate: Stage 6 로컬 vertical slice `Go`; Product Validation `Revise`; 서버 검증·실광고·실결제·출시 `Stop`.
- 상세: [Ranked Endless Concept](../03-product/descent-breaker-ranked-endless-concept.md), [Engineering Slice](../05-engineering/descent-ranked-endless-local-slice-2026-08-21.md), [QA Evidence](../06-quality/descent-ranked-endless-qa-2026-08-21.md).

## D-025 — Ranked Endless v2에 Combat Pressure와 기체 trade-off 채택

- 결정일: 2026-08-21 KST
- 사용자 근거: 오너는 현재 난이도가 너무 쉽고 한 발 처치와 단순한 공격 표현 때문에 기체 장점을 모으기 어렵다고 판단했다. 고득점 이후 고HP·공격형 몬스터, 저피해 다중 전기, 끊기지 않는 바람, 기체별 장점과 단점을 요청했다.
- 범위: 이 결정은 `descent-ranked-endless-local-r2`에만 적용한다. Revision 5 / Daily 60의 HP·기체 cadence·기존 전기 대상 수·fixture·checksum 계약은 유지한다.
- 난이도: score와 elapsed tick 중 높은 값을 T0–T6 위협으로 사용한다. 4,000점 또는 30초부터 16–32 HP Brute를, 10,000점 또는 Level 2부터 90-tick 경고 뒤 lane을 snapshot하는 공격 Drone을 활성화한다. 적탄은 피해 1, cap 12, breach와 같은 reactor cooldown을 사용한다.
- 기체: Swift는 `damage 2 / 24t / speed 1,000`, Hammer는 `5 / 32t / 620`, Trident는 `2×3 / 36t / 800`이다. Trident는 중앙탄만 원소 효과를 운반해 3중 proc을 금지한다. 한 발 처치는 Hammer 대 normal에만 남고 armored·Brute는 모두 multi-hit이다.
- 공격: Endless 전기는 직접탄 외 secondary damage 1로 L1/L2/L3에서 3/5/7명을 stable nearest-chain으로 공격한다. Scene은 실제 impact에서 갈라지는 branch로 표현한다. 바람 판정은 기존 zero-damage push를 보존하고 immutable origin/target cue로 연속 curve·vortex·arrow를 그린다.
- Conflict: Market은 8,000/25,000점의 완만한 진입과 run-local 기체 MK를, Engineering은 4,000/10,000점의 더 빠른 위협과 영구 기체 레벨 제외를 제안했다. Orchestrator는 “너무 쉽다”는 최신 관측에 맞춰 빠른 위협을 택하되 구매·계정 power와 Craft MK는 제외했다. 최초 Hammer 66t/Guardian 96t 후보는 reference에서 과도하게 약했고 Hammer 24t 후보는 지배적이어서 32t/36t로 재조정했다.
- 검증: SwiftPM 85/85, 20 seeds × 3 crafts × 2-minute reference의 provisional median gap 35% 이내, iPhone SE 전투/기체 선택 UI 2/2, Debug Simulator build를 통과했다. Computer Use 직접 검사에서 T3·Brute·Drone·적탄·전기 branch·연속 바람과 작은 화면의 기체 장단점 가독성을 확인했고 literal HP 텍스트 결함 1건을 수정 후 재확인했다.
- Gate: Stage 6 local implementation `Go`; 100-seed × 3-minute ≤8%, 10-minute soak, 실기기·접근성·5/10명 사용자 validation은 `Revise`; 통합 public leaderboard, 영구/유료 기체 power, 출시 성과 주장은 `Stop`.
- 상세: [Combat research](../01-research/descent-ranked-endless-combat-balance-2026-08-21.md), [Ranked Endless Concept](../03-product/descent-breaker-ranked-endless-concept.md), [Engineering Slice](../05-engineering/descent-ranked-endless-local-slice-2026-08-21.md), [QA Evidence](../06-quality/descent-ranked-endless-qa-2026-08-21.md).

## D-026 — 전기·바람 공격 cue를 비절단 presentation으로 분리

- 결정일: 2026-08-21 KST
- 사용자 근거: 오너는 공격 그래픽이 중간에 끊기지 않도록 요청했다.
- 결정: 전기·바람 cue를 파편·타격 spark·점수 label이 공유하던 `effectRoot`에서 전용 `skillCueRoot`로 분리한다. 장식 노드가 64개 cap을 넘더라도 이미 표시된 공격은 제거하지 않는다. 공격 cue 8개 cap이 찬 경우에는 화면에 아직 등장하지 않은 신규 cue를 생략하고, 진행 중 cue를 자르지 않는다.
- 좌표·모션: 바람 target은 권위 push가 끝난 좌표를 snapshot하고 origin과 전체 path는 고정한다. 기존 root 전체 +20pt 이동과 낮은 alpha 진입은 제거했다. 전기·바람 모두 첫 frame부터 완전한 underlay/core path를 표시하고, 경로를 따르는 bounded pulse/flow만 움직인다. camera impulse에는 object·skill cue·projectile·enemy projectile root를 같은 transform으로 포함한다.
- Conflict: Technical Art는 재귀 전체 64-node budget과 photosensitivity runtime policy를 함께 요구했고, Engineering은 active cue eviction 제거와 post-push 좌표를 최소 P0/P1 수정으로 보았다. Orchestrator는 판정과 체크섬을 바꾸지 않는 최소 presentation 수정을 채택하고, 전체 재귀 node probe·3Hz 광과민 정책·10분 soak는 Release Gate로 남겼다.
- 검증: SwiftPM 86/86, iOS Simulator Debug build, `testRankedEndlessCombatV2ExposesThreatAndHostileAttack` 1/1을 통과했다. 새 회귀 테스트는 wind cue target이 push 뒤 object 좌표와 정확히 같은지 검증한다. UI 테스트 첨부 화면에서 전기 branch와 바람 curve가 실제 target까지 연결되고 danger line·enemy projectile 가독성이 유지됨을 확인했다.
- Gate: Stage 6 local implementation `Go`; 60fps L3 즉사 burst·30-tick catch-up·Reduce Motion·10분 node recovery·실기기 성능은 `Revise`; 공개 출시와 체류 개선 주장은 `Stop/미확인`.
- 상세: [QA Evidence](../06-quality/descent-ranked-endless-qa-2026-08-21.md), [검증 화면](../screenshots/descent-2026-08-21-combat-balance/endless-vfx-continuity-after.png).

## D-027 — GPT Combat Signature v1을 additive presentation adapter로 제한 적용

- 결정일: 2026-08-21 KST
- 사용자 근거: 오너는 현재 개발된 게임에 GPT로 디자인 애셋을 더 개발해 업데이트하도록 요청했다.
- 결정: 전면 아트 교체나 규칙 변경 대신 전기 impact core, 바람 lift core, 플레이어 reactor aura 3개만 생성한다. 전기·바람의 권위 좌표와 절차형 연결 경로는 유지하고 생성물은 origin motif로만 합성한다.
- 투명도 Conflict: Imagegen의 투명 생성과 배경 추출 편집이 모두 실제 alpha 없는 RGB 체크무늬로 확인되어 후보 6개를 반려했다. 최종본은 순수 검정 배경의 additive 전용 RGB로 재생성해 `.add`로만 사용하며, 투명 PNG라고 허위 기록하지 않는다.
- 품질 경계: 런타임 파생본은 각 축 최대 512px, 합계 디코딩 약 2.8MiB 이내다. VFX는 danger line·적 탄환·HP보다 낮은 정보 우선순위를 유지하고 Reduce Motion에서 alpha를 낮춘다.
- 시장 근거: 2026-08-21 한국 iPhone Action 무료와 인접 세로 슈팅 관측은 화려함 자체보다 픽셀/기체/강화의 식별 가능한 형태를 전면에 둔다. 차트가 특정 스타일의 성공 원인을 증명하지는 않으므로, 색만 바꾸는 네온 원·직선 레이저·과밀 AI 콘셉트보드는 피한다.
- Gate: 로컬 build·asset load·Simulator A/B와 Vision 가독성 검사가 통과하면 Stage 6 prototype은 `Go`; 5/10명 블라인드 선호·실기기·광과민·10분 성능·출시 권리는 `Revise/Stop`으로 남긴다.
