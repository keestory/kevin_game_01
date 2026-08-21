# Return Shot 테스트 계획

- 기준일: 2026-08-18 KST
- 기준 계약: `docs/product-specs/return-shot-chain.product-spec.md` rev3
- 단계: Stage 6 Implementation
- 원칙: 코드·XCUITest·스크린샷은 실제 사용자 재미와 실기기 성능을 대체하지 않는다.

## 자동 규칙 테스트

| 범위 | 필수 계약 |
|---|---|
| 결정성 | 같은 seed 구조, 30/60/120Hz 합성 입력 checksum 동일 |
| 반사 | 접촉 offset과 패들 속도가 각도를 바꾸고 수평 무한 왕복 방지 |
| 충돌 | swept collision로 빠른 공의 tunneling 0 |
| LINK | 색·무늬·마크 독립, 정확히 5회에 6초 power 1회 |
| 프리즘 | 3HP, 반복 적중 LINK farming 금지, 완파/낙하 중복 없음 |
| 마이너스 | 직접 `−250`, cooldown·최대 2회, 지지 붕괴 `+120` |
| support graph | 모든 참조 유효, 제거 transaction 결정론적 |
| 스킬 코어 | 구조당 1개·4종 순환·직접 완파만 수집·종류별 L3 cap |
| 공격 범위 | 번개 1/2/3, 화염 반경·3/5/7, 바람 상단 2/3/4, 관통 1/2/3 charge |
| 공격 안전성 | negative/carrier 제외, 재귀 수집 0, LINK 변화 0, 파동 combo 최대 1 |
| 방어막 | 구조 1~3=0, 4~6=1, 7+=2; core HP보다 우선; 점수 중복 0 |
| UI band | 권위 공이 HUD·coachmark 예약 영역에 진입하지 않음 |
| 기록 | score·height·combo·PB delta 계약과 저장 migration |

현재 `AppStoreGameTests/GameRulesTests.swift`의 25개 테스트가 위 범위를 실행한다.

## UI 흐름

`AppStoreGameUITests`는 격리된 seed 42와 fast-fail hook으로 다음을 검증한다.

1. 홈의 시작 CTA 존재
2. 시작 후 SpriteView 존재
3. 한 엄지 drag 입력
4. 스킬 코어 HUD 존재와 게임 화면 캡처
5. 일시정지 overlay와 재개
6. 결과 화면과 기록 delta
7. `같은 구조 다시` 후 새 gameplay Scene

테스트 hook은 Release 규칙을 바꾸지 않으며 종료는 재개 뒤에만 arm한다.

## 시각·반응형 QA

| 화면 | 증거 | 현재 |
|---|---|---|
| iPhone 17 Pro A/B | home, game, result 캡처 | Pass |
| iPhone 17e A | game 캡처 | Pass |
| iPhone SE 3세대 375×667 A | game 캡처 | Pass |
| SE home/result | 750×1334 캡처와 전체 UI 흐름 | Pass |
| 최대 Dynamic Type·Increase Contrast | 실제 화면 검사 | Pending P1 |
| VoiceOver·Switch Control | 핵심 흐름 실사용 | Pending P1 |

Vision 검사는 위계·간격·대비·텍스트·반응형·모바일·터치 명확성을 화면마다 확인한다. iPhone 앱에서 hover는 N/A이며 44pt target과 pressed state로 대체한다.

## 수동 사용자 Gate

- 5명 중 4명: 설명 없이 5초 안에 첫 리턴
- 5명 중 3명: 자발적 세 번째 run
- Run 3 score 또는 height 중앙값: Run 1 대비 `+20%`
- active-touch 중앙값 `≥60%`
- 5명 중 4명: LINK·프리즘·마이너스 간접 제거 설명
- 5명 중 4명: 코어가 들어 있는 벽돌과 획득한 스킬 레벨을 색 없이 구분
- 5명 중 4명: 방어막과 core HP의 차이를 첫 armor 구조에서 설명
- 불공정 죽음·공 관통·중복 점수: 0건

## 실기기 성능·안정성

- 최소 지원 iPhone 10분 soak, 목표 60fps·hard floor 30fps
- 100ms 초과 gameplay hitch 0회
- retry 20회 뒤 메모리 증가 5MB 이하, leak 0
- background/foreground, 저전력, 열상태, 메모리 경고, Reduce Motion

## 재현 명령

```sh
swift test --scratch-path /private/tmp/ReturnShotSwiftPM
```

```sh
xcodebuild -project AppStoreGame.xcodeproj -scheme AppStoreGame \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -derivedDataPath /private/tmp/ReturnShotTestDerived \
  CODE_SIGNING_ALLOWED=NO test
```

추가 필수 검사: `plutil -lint`, `git diff --check`, secret scan, asset provenance hash, Assets.car contents. Release에는 signed archive/export와 App Store Connect 교차 확인을 추가한다.

## Descent Breaker Choice Arena 및 로컬 연구 회귀 — 2026-08-20

### 자동 계약

- Choice는 tick 3600 transaction과 finish 뒤 run당 1회 제시되고 대기 중 state·entity·score·checksum이 불변이다.
- 레드라인 118% 낙하와 기본탄 직접 파괴 135% 점수는 선택 다음 tick부터만 적용한다. Danger Save·5속성·drop·HP·3기체 계약은 불변이다.
- background 중 선택 latency를 세지 않으며 foreground 복귀 때 자동 재개하지 않는다.
- overlay 전 carried drag는 카드 선택에 쓰지 않고 새 tap만 받는다.
- A `noArena`는 Choice UI·research Choice event·simulation pause가 모두 0건이다.
- research logger는 event logical exactly-once, terminal ordering, run-ID upsert, 1MB/100-run hard stop, corrupt/future line fail-closed, 저장 실패 UI 전파, raw touch·신원 필드 금지, 권위 checksum 비영향을 검증한다.
- Research report는 고정 AB/BA, run 2의 60초 optional marker, 동일 seed·ship run 3 terminal, ITT 10명 R20, 필수 run active-touch 중앙값, stable CSV와 DQ violation 정렬을 검증한다.

### 연구 시작 전 수동 Gate

- 375×667과 402×874에서 heading·scope·두 카드·CTA clipping 0, hit target 44pt 이상.
- VoiceOver focus가 heading→pace→안정→레드라인 순이며 background HUD는 숨김.
- P01…P10 AB/BA 5:5, 참가자 내 seed·ship·기기 동일, fresh PB=0.
- 각 started run은 finished 또는 explicit abandoned terminal 정확히 1개. A의 Choice event 0, B 도달 run의 presented/selected 각 1개.
- 사용자 연구 판정은 [analytics plan](../03-product/analytics-plan.md)의 참가자 단위 Primary와 Stop 기준을 사용한다.
- 진행자는 [Choice Arena Research Runbook](../07-operations/choice-arena-research-runbook.md)의 배정 명령·중립 멘트·export·삭제 절차를 사용한다.

### 최신 영수증

- SwiftPM core: 58/58 Pass.
- Xcode unit·asset·analytics: 70/70 Pass, xcresult `/tmp/ChoiceArenaResearchUnit/Logs/Test/Test-AppStoreGame-2026.08.20_08-26-47-+0900.xcresult`.
- iPhone 17 Pro Choice lifecycle/carry-touch/no-Arena: 3/3 Pass, xcresult `/tmp/ChoiceArenaResearchUIPro/Logs/Test/Test-AppStoreGame-2026.08.20_08-30-42-+0900.xcresult`.
- 375×667 SE Choice redline/result/no-Arena: 2/2 Pass, xcresult `/tmp/ChoiceArenaResearchUISE/Logs/Test/Test-AppStoreGame-2026.08.20_08-32-20-+0900.xcresult`.
- SE 첨부 화면 직접 검사: Choice heading·pace·두 카드·scope note와 결과 CTA clipping 0; 선택 후 player·projectile·object·danger line 가림 0. hover는 iPhone에서 N/A이며 pressed/tap 상태로 검증한다.

### Research Console fail-closed 영수증 — 2026-08-20 09:20 KST

- SwiftPM authoritative core: 58/58 Pass, scratch `/tmp/AppStoreGameResearchSwiftPM2`.
- 최종 Xcode unit·rules·art·analytics·report: 84/84 Pass, fail/skip 0. xcresult `/tmp/AppStoreGameResearchDQFinal/Logs/Test/Test-AppStoreGame-2026.08.20_09-19-08-+0900.xcresult`.
- DQ·report 집중 회귀: 20/20 Pass. 손상 JSONL에서 summary CSV 차단, 저장 실패 표면화, AB/BA·optional third-run·ITT R20·stable CSV를 포함한다.
- iPhone 17 Pro: Research Console sample 1/1 Pass, 잘못된 배정 차단 1/1 Pass. 최신 console xcresult `/tmp/AppStoreGameResearchUIPro3/Logs/Test/Test-AppStoreGame-2026.08.20_09-18-02-+0900.xcresult`.
- 375×667 iPhone SE: Research Console 1/1 Pass. xcresult `/tmp/AppStoreGameResearchUISE2/Logs/Test/Test-AppStoreGame-2026.08.20_09-13-15-+0900.xcresult`.
- SE screenshot 직접 검사: DQ→필수 수집→Primary→P01–P10→export 순서, 텍스트 대비, 44pt control, 가로 clipping 0. 참가자 count는 `A n회 · B n회`로 표시한다.
- Release generic iOS Simulator build Pass. Release binary에서 `RESEARCH CONSOLE`, `descentResearchConsole`, sample launch string 0건. 기존 사용자 소유 `AppIcon 2.png` unassigned-child warning은 남아 있다.

### Persistent Effects v1.1 native adaptation 영수증 — 2026-08-20 23:25 KST

- patch SHA manifest: 30/30 Pass; manifest SHA-256 `b681900ec1e5175a2a06c2d1212a3dcd192d2405e02b46322951f1aad154c4a2`.
- SwiftPM core: 61/61 Pass. pickup combat 0, immutable volley snapshot, old projectile 비소급, persistent impact와 recursive drop 0을 포함한다.
- Debug·Release generic iOS Simulator app build: Pass. 기존 사용자 소유 `AppIcon 2.png` unassigned-child warning은 비차단 P1으로 남는다.
- iPhone 17 Pro unit·asset·analytics·research report: 88/88 Pass, fail/skip 0. 이전 rules version fail-closed를 포함한다. xcresult `/tmp/DescentPersistentPatchXcodeTests2/Logs/Test/Test-AppStoreGame-2026.08.20_23-27-47-+0900.xcresult`.
- iPhone 17 Pro UI: 핵심 full flow와 Choice Arena redline 2/2 Pass. xcresult `/tmp/DescentPersistentPatchXcodeUI/Logs/Test/Test-AppStoreGame-2026.08.20_23-22-59-+0900.xcresult`.
- 남은 P1 evidence: pickup 뒤 fire/electric/pierce/wind/explosion visual 구분, 최소 기기 10분 성능, VoiceOver·Switch Control·최대 Dynamic Type.

### Revision 5 BREAK FLOW 구현 영수증 — 2026-08-21 KST

- SwiftPM authoritative core: 70/70 Pass. 8-chain, 192-tick inclusive, next-tick start, 360-tick expiry/refresh, direct-only charge·bonus, skill/echo 제외, Redline 가산, Choice freeze, 30/60/120Hz checksum과 frenzy terminal counters를 포함한다.
- iPhone 17 Pro Xcode unit·rules·asset·analytics·report: 97/97 Pass, fail/skip 0. xcresult `/tmp/DescentBreakFlowUnit3.xcresult`.
- iPhone 17 Pro 일반 제품 UI 회귀: 14/14 Pass. 환경 변수로만 실행하는 30초 영상 데모 1건은 의도적으로 skip. xcresult `/tmp/DescentBreakFlowUI.xcresult`.
- Revision 5 research report 집중 회귀: 12/12 Pass. frenzy CSV 필드와 잘못된 bonus breakdown fail-closed를 포함한다. xcresult `/tmp/DescentBreakFlowReportFinal/Logs/Test/Test-AppStoreGame-2026.08.21_00-17-18-+0900.xcresult`.
- 402×874와 375×667 최신 일반 run 직접 캡처에서 `CHAIN`, 8칸 meter, 5스킬 rail, pause·score·time·HP·danger feedback의 가로 clipping과 플레이어·위험선 가림은 0건이다. frenzy 활성 프레임은 권위 시험만 통과했으며 별도 실제 캡처가 남았다.
- 남은 Gate: 100-seed active/no-input agency reference, BF01–BF05 연구 배정·집계, 5명 방향성 연구, frenzy 활성 프레임·최소 실기기 성능·접근성.

### Ranked Endless v2 Combat Pressure 영수증 — 2026-08-21 KST

- SwiftPM authoritative core: 85/85 Pass. Endless threat/HP boundaries, Brute, Drone projectile one-shot resolution, reactor cooldown, three-craft cadence/mobility, Trident center-only elemental proc, electric 4/6/8 visual targets, Revision 5 3-target regression, checksum and 30/60/120Hz scheduling are included.
- Provisional balance: 20 seeds × 3 crafts × 14,400 ticks; highest/lowest two-minute median score gap ≤35% Pass. This is a domination screen, not the combined-board ≤8% Gate.
- iPhone SE 375×667: Ranked preflight/craft trade-off and T3 Brute/Drone/hostile-projectile combat UI 2/2 Pass.
- Direct Simulator inspection: T3 badge, numeric Brute HP, Drone warning/bolt, actual-origin electric branches, continuous wind curves, and visible danger line observed. Custom accessibility lane action and Hammer selection completed. Literal interpolation text found in the first inspection was fixed and rechecked.
- Debug Simulator build: Pass. Existing unassigned `AppIcon 2.png` warning remains.
- Remaining: 100 seeds × 3 minutes at ≤8%, 10-minute worst-case soak/node recovery, 390×844 and 430×932, physical-device FPS/thermal/haptics, VoiceOver/Switch Control/Dynamic Type/Increase Contrast/photosensitivity/color-assist, and 5/10-person comprehension/fairness.

### Continuous Attack VFX 영수증 — 2026-08-21 KST

- SwiftPM authoritative core: 86/86 Pass. Wind cue가 push 뒤 권위 object 좌표와 일치하는 회귀를 포함한다.
- iPhone SE iOS 26.5 Simulator Debug build: Pass.
- Ranked Endless combat XCUITest: 1/1 Pass. current-build attachment에서 electric full branches, wind full curves, target markers, danger line, enemy projectile 동시 가독성을 확인했다.
- Structural lifecycle: skill cue와 장식 transient를 분리하고, 표시 중 cue의 cap eviction을 제거했다. saturated 상태에서는 신규 cue를 first frame 전에 생략한다.
- Remaining Gate: L3 7-target instant destruction 60fps sequence, 9-cue overload accounting, 30-tick catch-up, Reduce Motion, photosensitivity 3Hz policy, 10-minute node recovery, physical-device FPS/thermal.

## 최신 영수증

- SwiftPM: 25/25
- Xcode unit: 25/25
- XCUITest: 1/1, 23.107초
- iPhone SE XCUITest: 1/1, 18.656초, 375×667 game 캡처 Pass
- 합산: 26/26. 규칙과 최종 UI는 아래 분리 영수증으로 확인했다.
- unit xcresult: `/private/tmp/ReturnShotSkillCoreUnitFinalDerived/Logs/Test/Test-AppStoreGame-2026.08.18_01-37-16-+0900.xcresult` (unit 25/25)
- final UI xcresult: `/private/tmp/ReturnShotSkillCoreFinalDerived/Logs/Test/Test-AppStoreGame-2026.08.18_01-29-32-+0900.xcresult` (UI 1/1)
- SE UI xcresult: `/private/tmp/ReturnShotSkillCoreSEDerived/Logs/Test/Test-AppStoreGame-2026.08.18_01-31-50-+0900.xcresult` (UI 1/1)
