# Descent Breaker Persistent Effects Patch v1.1 — Native Import Record

- 확인일: 2026-08-20 KST
- 입력: 사용자가 제공한 로컬 patch folder
- 원본 manifest entries: 30
- `SHA256SUMS.txt` 검증: 30/30 Pass
- manifest file SHA-256: `b681900ec1e5175a2a06c2d1212a3dcd192d2405e02b46322951f1aad154c4a2`
- 로컬 구현 Gate: Go
- 공개 GitHub / App Store Release Gate: Stop

## 권위 경계

Patch의 문서·TypeScript·token·task는 제품 입력 자료이며 저장소의 플레이북, ProductSpec, Swift 코드와 테스트를 대체하지 않는다. 원본 파일을 앱 bundle, Xcode build phase, SwiftPM source 또는 runtime JSON에 추가하지 않았다.

## 채택·변환·제외

| Patch concept | 판정 | Native 적용 |
|---|---|---|
| 다섯 종류 run-local L0…L3 | Adopt | `DescentSkillLevels` 유지, L3 중복은 `MAX` 표시 |
| pickup 순간 combat 0 | Adopt | level·loadout version·feedback만 변경 |
| projectile/volley snapshot | Adopt | 같은 volley가 immutable `DescentProjectileEffectSnapshot` 공유 |
| 기존 projectile 비소급 | Adopt | 새 발사부터 갱신된 snapshot 적용 |
| persistent impact effects | Adapt | 현 3HP·5-lane·entity cap에 맞춘 deterministic bounded 수치 |
| TypeScript/Vite runtime | Reject | Swift 6·pure `GameRules`·SpriteKit 유지 |
| 90초, 7 lanes, web viewport | Reject | 현 60초, 5 lanes, iPhone portrait 유지 |
| patch exact VFX/particle 수치 | Reject | 현 accessibility·transient cap 우선 |
| patch validation의 108 PNG Pass 주장 | Evidence reject | package manifest가 runtime asset 0 / assets not included로 명시해 시각 증거로 사용 불가 |

## Native effect contract

- Fire: direct stable ID에 L1 `+60`, L2 `+45/+90`, L3 `+30/+60/+90` tick echo, retarget 0.
- Electric: direct 포함 총 3/4/5 target, secondary damage 1, stable order.
- Pierce: 새 lead projectile hit capacity 3/5/7, Trident side projectile 1, 만료 없음.
- Wind: impact radius 120/150/180pt, 3/4/5 target을 12/18/24pt 위로 이동, damage 0.
- Explosion: first impact only, radius 96/112/128pt, 추가 2/3/4 target damage 1/1/2.
- Skill wave의 drop 생성과 재귀 activation은 금지한다.

## 변경 파일

- `AppStoreGame/Game/DescentModels.swift`: snapshot·loadout version·MAX display·event payload.
- `AppStoreGame/Game/DescentRules.swift`: pickup-only loadout 갱신, volley snapshot, impact resolver, checksum.
- `AppStoreGame/Game/DescentGameScene.swift`: pickup 흡수 연출, persistent projectile cue, feedback.
- `AppStoreGame/Analytics/DescentResearchAnalytics.swift`: research rules version 상수.
- `AppStoreGameTests/DescentRulesTests.swift`: pickup 0-combat, snapshot 불변·공유, 지속 효과·재귀 방지 회귀.

## 검증

- SwiftPM: 61/61 Pass.
- Xcode Debug·Release generic iOS Simulator app build: Pass.
- Xcode iPhone 17 Pro Simulator unit·asset·research tests: 88/88 Pass, fail/skip 0. 이전 rules version의 연구 데이터 fail-closed를 포함한다.
- Xcode iPhone 17 Pro Simulator UI flows: 2/2 Pass (`home→ship→play→pause→result→retry`, `Choice Arena→redline→result`).
- SHA-256 manifest: 30/30 Pass.
- `GameRules` authority: 120Hz fixed tick 유지.
- 미실행: pickup 이후 다섯 effect의 수동 visual comparison, 최소 지원 실기기 10분 성능, VoiceOver/Switch Control/최대 Dynamic Type, P01–P10 사용자 연구.

## 권리·게시 제한

Patch에는 LICENSE, NOTICE, AUTHORS 또는 상업·수정·공개 재배포 허가가 없다. 사용자가 제공한 로컬 입력을 네이티브 개념으로 수동 번역했지만, 원본 patch 자체와 exact visual/token을 공개 저장소나 App Store 산출물에 게시하는 권리는 확인되지 않았다. 권리자가 사용 범위를 확인하기 전 공개 commit·배포는 Stop이다.
