# Descent Breaker — 60초 비교 Vertical Slice ProductSpec

- Revision: 5
- Date: 2026-08-20 KST
- Stage: 4 Solution Definition
- Status: Conditional Go for BREAK FLOW implementation and isolated validation; product pivot is not approved
- Reference: user-provided 1280×960 JPEG, SHA-256 `e0233b9e840d52ae8c46029846f90c3ea93f8d8432ed10c010902e22835dcd50`
- Patch input: user-provided `descent-breaker-persistent-effects-patch-v1.1`; 30/30 manifest entries verified, manifest SHA-256 `b681900ec1e5175a2a06c2d1212a3dcd192d2405e02b46322951f1aad154c4a2`

## Product Summary

`Descent Breaker`는 위에서 내려오는 오브젝트를 하단의 플레이어가 자동 사격으로 파괴하고, 파괴된 코어에서 떨어지는 원소 아이템을 직접 받으러 이동해 run 안에서 공격을 강화하는 한 손 세로형 액션이다. 핵심 판단은 위험선에 가까운 오브젝트를 막는 것과 다음 공격 코어를 받기 위해 lane을 바꾸는 것 사이의 선택이다.

Return Shot은 A/B baseline으로 보존한다. 두 루프의 물리·상태·스킬 타입을 혼합하지 않는다.

## Scope

In:

- 390×844pt, 5 lanes, 60초 run, reactor 3HP.
- 상대 좌우 drag, 자동 사격, lane-fixed 수직 낙하.
- 출격 전에 세 기체 중 하나를 선택하고, 기체마다 서로 다른 기본 미사일 패턴을 사용한다.
- 일반 상자, 강화 블록, 스파이크 오브, 드론, 엘리멘탈 코어.
- 불·전기·관통·바람·폭발의 별도 run-local L0…L3.
- score, combo, danger save, PB pace, 같은 seed 즉시 재시작.
- 직접탄 연속 파괴로만 발동하는 bounded `BREAK FLOW / COMBO FRENZY`.
- 30초에 한 번 `안정 비행`과 `레드라인` 중 선택하는 Choice Arena.
- 결정적 spawn/drop/target order와 120Hz 권위 simulation.

Out:

- 적 탄환, 미니보스, 회전·지그재그 이동, 수동 스킬 버튼·cooldown.
- 영구 강화, 재화, 장비, 광고, continue, 친구 초대, 결제.
- 60초 이후 `+15초` checkpoint·endless continue와 run 밖 meta power.
- run 중 기체 교체, 기체별 HP·이동속도·스킬 슬롯·해금 비용.
- 기존 `AttackItemKind` 또는 Return Shot checksum/state 변경.

## Input and Field

- Lane centers: `39 / 117 / 195 / 273 / 351`.
- HUD 76pt, spawn `y=738`, danger line `y=128`, player `y=84`.
- X만 사용하며 입력은 1pt 단위로 양자화한다. player 최대 이동속도는 900pt/s다.
- 탄속은 780pt/s다. 자동 발사 간격·탄 수·damage는 선택한 기체의 Loadout Contract를 따른다.
- 플레이어 직접 피격은 없다. 오브젝트가 danger line을 넘으면 reactor가 1 damage를 받는다.
- 54 ticks 안의 복수 breach는 reactor damage 1회로 합치고 combo를 0으로 만든다.
- 전체 SpriteKit field drag가 입력 영역이다. 하단의 조작기처럼 보이던 reactor bar는 표시하지 않고 기체만 남긴다. reactor 3HP는 상단 HUD에서만 표시한다.

## Loadout Contract

출격 전 full-screen preflight에서 카드를 탭해 선택하고 CTA로 확정한다. 카드 탭은 곧바로 run을 시작하지 않는다. 같은 seed 재시도는 선택한 기체를 유지하며 run 중 교체는 허용하지 않는다.

| Ship | Role | Missile | Interval | Projectiles | Damage |
|---|---|---|---:|---:|---:|
| Swift S-1 | precision rapid fire | pulse | 22 ticks | current lane 1 | 1 |
| Hammer H-2 | armor breaker | lance | 44 ticks | current lane 1 | 2 |
| Trident T-3 | multi-lane intercept | salvo | 66 ticks | sliding 3-lane window | 1 each |

- 세 기체의 이론 총 DPS는 모두 5.45로 맞춘다. 이동속도, reactor HP, pickup 반경, spawn과 score 규칙은 동일하다.
- Trident는 양 끝 lane에서도 선택 lane을 포함한 서로 다른 세 lane을 보장한다. projectile cap 여유가 3 미만이면 일부만 발사하지 않고 volley 전체를 건너뛴다.
- 관통 charge는 volley당 1만 소모한다. Swift/Hammer는 해당 1발, Trident는 선택 lane의 lead projectile만 관통하며 side projectile은 관통하지 않는다.
- 기체는 기본 발사 수·silhouette·rhythm을, 원소 아이템은 drop 획득 후 효과·색·명칭을 나타낸다. 두 체계를 별도 level이나 stat bar로 중복 표기하지 않는다.

## Object Contract

| Kind | HP | Fall multiplier | Score | Non-color cue |
|---|---:|---:|---:|---|
| normal | 1 | 1.00 | 100 | wooden square silhouette |
| armored | 3 | 0.78 | 300 | metal plate and three HP pips |
| spike | 2 | 1.22 | 220 | spiked outline |
| drone | 2 | 1.08 | 250 | wings and center lens |
| core | 2 | 0.90 | 250 | diamond core and item mark |

동일 tick에서는 projectile hit → destruction/drop → danger crossing 순서로 처리한다. Object당 destroy, score, drop은 각각 최대 1회다. Drop kind는 spawn 시 `(seed, objectID, salt)`로 결정하며 파괴 순서에 따라 바뀌지 않는다.

## 60-second Difficulty

| Time | Base fall speed | Spawn interval | Pattern |
|---|---:|---:|---|
| 0–15s | 72pt/s | 1.50s | single rain |
| 15–30s | 84pt/s | 1.20s | split pair |
| 30–45s | 98pt/s | 0.95s | stair sequence |
| 45–60s | 112pt/s | 0.82s | cluster gate |

- 최소 spawn-to-danger는 3.5초다.
- active object ≤36, projectile ≤24, drop ≤8, presentation transient ≤64다.
- 첫 run의 core carrier는 약 6.5s, 21s, 36.5s에 배치한다. Seed rotation으로 세 종류만 보장하고, 두 seed를 합쳐 다섯 스킬을 검증한다.

## Drop and Persistent Effects

Drop은 원래 lane으로 160pt/s 하강하며 player와 34pt 이내면 자동 획득한다. 획득 순간에는 damage·score·combo·object 제거가 0이며, loadout만 L0→L1→L2→L3으로 갱신한다. L3 중복 획득은 rank를 올리지 않고 `MAX`로 표시한다. 새 drop은 생성 다음 tick부터 획득할 수 있다.

발사 한 번마다 다섯 효과 level과 loadout version을 immutable snapshot으로 만든다. 같은 volley의 모든 projectile은 같은 snapshot을 공유하고, 이미 화면에 존재하는 projectile은 이후 drop을 획득해도 바뀌지 않는다. 효과는 snapshot을 가진 projectile이 object에 직접 충돌할 때만 발동한다.

| Skill | L1 / L2 / L3 persistent impact contract |
|---|---|
| fire | 직접 맞은 동일 stable ID에 60 / 45·90 / 30·60·90 ticks 뒤 1 echo damage; retarget 금지 |
| electric | 직접 target을 포함해 danger에 가까운 3 / 4 / 5 targets; secondary에 1 damage |
| pierce | 새 lead projectile이 총 3 / 5 / 7 objects까지 관통; 만료 없음 |
| wind | 충돌점 반경 120 / 150 / 180pt 안의 3 / 4 / 5 targets를 12 / 18 / 24pt 위로 이동; damage 0 |
| explosion | 첫 impact에서만 반경 96 / 112 / 128pt의 추가 2 / 3 / 4 targets에 1 / 1 / 2 damage |

- Trident의 side projectile은 관통 level과 무관하게 1회 hit이며 선택 lane lead projectile만 pierce snapshot을 소비한다.
- target은 impact distance, danger proximity, stable ID로 결정하며 같은 shot의 delayed effect는 신규 target으로 바꾸지 않는다.
- 스킬 wave는 drop을 만들거나 다른 스킬을 재귀 발동하지 않는다. 직접 projectile hit만 원래 object의 drop을 만들 수 있다.
- projectile 한 번에서 persistent effect들의 combo 증가는 합계 최대 +3, field removal은 50%, run score contribution은 25%를 넘지 않는다.

## Score and End

- 파괴 기본점수에 `min(2.0, 1 + 0.1 × floor(combo/5))`를 곱한다.
- 마지막 파괴 후 1.6초 안에 다음 파괴하면 combo +1, 아니면 1로 재시작한다.
- danger line 48pt 이내 파괴는 `DANGER SAVE +150`이다.
- 60초 생존 또는 reactor 0 이후 0.6초 안에 결과로 이동한다.
- Primary record는 score, secondary는 max combo, danger saves, collected skill ranks다.

## BREAK FLOW / COMBO FRENZY — Revision 5 Delta

이 규칙은 60초 안에서 반복 조작과 파괴 리듬이 기록 상승으로 이어지는지를 검증하는 공통 core다. 체류·retention 상승은 **내부 가설**이며 2026-08-20 한국 iPhone Games 시장이나 실제 사용자 데이터로 검증되지 않았다.

- `rulesVersion`은 A/B 양쪽 모두 정확히 `descent-rev5-break-flow-frenzy-r1`이다. Revision 4 또는 다른 rules version의 run은 Revision 5 판정에 혼합하지 않는다.
- qualifying chain은 **직접 projectile이 파괴한 object**만 센다. 직전 qualifying 파괴와의 간격이 192 authoritative ticks 이하이면 chain +1, 초과이면 새 chain 1로 시작한다. skill wave·delayed echo·collapse 등 비직접 파괴는 chain을 올리거나 192-tick 창을 갱신하지 않는다.
- 8번째 qualifying 직접 파괴가 tick `T`에 확정되면 같은 transaction에는 bonus를 주지 않고 다음 authoritative tick `T+1`부터 `T+360`까지 COMBO FRENZY를 활성화한다. trigger 뒤 chain counter는 0으로 재설정한다.
- frenzy가 활성인 동안 tick `U`의 직접 projectile hit마다, 파괴 여부와 무관하게 활성 종료 tick을 `U+360`으로 갱신한다. 같은 tick의 복수 hit은 동일 종료값으로 합치며 skill hit은 갱신하지 않는다.
- frenzy 중 직접 projectile 파괴에는 기존 `baseComboPoints`의 20%를 정수 내림한 `frenzy_bonus_score`로 더한다. 레드라인과는 곱하지 않고 가산한다. 즉 둘 다 활성일 때 직접 파괴 점수는 `baseComboPoints + floor(0.35×baseComboPoints) + floor(0.20×baseComboPoints)`다.
- 기존 combo 증가·1.6초 grace, projectile·skill damage, persistent effect와 target order, drop 생성·획득, spawn plan·속도, reactor HP, Danger Save는 바꾸지 않는다.
- frenzy state·chain·마지막 qualifying 파괴 tick·종료 tick·bonus 누계는 checksum과 replay에 포함하고, 120Hz fixed tick의 ordered transaction만 권위로 사용한다. wall clock·frame rate·VFX callback은 발동·연장을 바꾸지 않는다.
- 결과와 연구 로그는 총점과 별도로 `frenzy_bonus_score`를 보존한다. `FrenzyScoreShare = frenzy_bonus_score / score`이며 score가 0이면 0으로 정의한다.

## Choice Arena

- authoritative tick 3600의 projectile hit → destruction/drop → pickup → breach → finish 처리를 끝낸 뒤 생존 중이면 run당 정확히 한 번 제시한다.
- Arena가 열린 동안 authoritative tick, spawn, projectile, object, drop, score, combo와 60초 제한시간을 모두 정지한다. 선택 체류시간은 run 시간에 포함하지 않는다.
- 기존 drag 종료 뒤 새 tap만 선택으로 받으며, overlay 진입 후 350ms 동안 입력을 막아 carried touch 오선택을 방지한다. 제한시간과 자동선택은 없다.
- `안정 비행`: 속도와 점수 규칙을 바꾸지 않고 즉시 이어서 플레이한다.
- `레드라인`: 선택 다음 authoritative tick부터 object fall과 상대 충돌 delta를 118%로 올리고, 기본 미사일의 직접 파괴 base+combo 점수만 135%로 계산한다.
- Danger Save +150, skill wave의 damage·score, drop, L0…L3, 기체 loadout, 관통 charge, reactor HP는 변경하지 않는다.
- 결과에는 `CHOICE: 안정 비행` 또는 `CHOICE: 레드라인 +N`을 표시하고, same-seed retry에서도 30초에 다시 선택한다.
- Choice Arena는 6번째 스킬이나 영구 upgrade가 아니다. 기존 core 파괴 → drop 직접 수집의 원소 성장 루프와 UI rail을 공유하지 않는다.

계측 후보는 `choice_presented`, `choice_selected`, `choice_latency`다. 속성은 run ID, ship, seed, 현재 점수, PB, choice, latency, redline bonus로 제한하고 개인정보는 수집하지 않는다. 분석 SDK가 아직 없으므로 이 이벤트는 구현 완료가 아닌 Launch & Learn 요구사항이다.

## First 30 Seconds

1. 0–3s: `끌어서 조준 · 자동 발사`, 첫 파괴 목표 ≤3s.
2. 3–8s: 설명 없는 lane 이동과 파괴.
3. 8–12s: 첫 core와 `아이템 쪽으로 이동` 1회.
4. 12–20s: armored HP pips 학습.
5. 20–30s: 첫 danger 접근에서 `빨간 선 전에 파괴` 1회.
6. Coachmark는 simulation과 입력을 멈추지 않는다.

## Presentation and Accessibility

- Z: background -100, lane -50, danger 0, object 20, impact 25, HP 28, projectile 30, drop 35, player 40, warning 50, HUD 100.
- VFX가 player, drop, 최저 위험 object, danger line을 100ms 이상 가리면 실패다.
- Hit flash ≤70ms, screen flash alpha ≤0.12/80ms, camera impulse ≤4pt/100ms.
- 색 외에도 silhouette, HP pip, icon, 한글명, hatch danger signal을 사용한다.
- Reduce Motion은 shake·zoom을 제거하고 trail을 50% 이하로 줄인다.
- VoiceOver/Switch Control은 lane n/5 adjustable과 좌우 custom actions를 제공한다.

## Acceptance Criteria

1. 5명 중 4명이 3초 노출 후 `움직여서 떨어지는 것을 선 전에 부순다`고 설명한다.
2. 첫 무도움 이동 ≤2s, 첫 파괴 ≤3s, 첫 drop 획득 중앙값 ≤12s다.
3. active-touch 중앙값 ≥60%, 의미 lane 변경 20–40회/분이다.
4. 같은 seed와 양자화 input의 7200 ticks가 30/60/120Hz와 large-delta batch에서 checksum/event/score가 같다.
5. 10,000 seeds에서 unreachable drop, unavoidable first-60s breach, entity cap 초과가 0이다.
6. 동일 tick multi-hit에도 destroy/drop/score/pickup/activation은 각각 1회다.
7. pickup의 combat event가 0이고, 새 volley snapshot만 L1…L3/MAX를 반영하며 기존 projectile은 비소급이다. 다섯 효과의 target·delay·radius·L3 cap이 정확하고 재귀 drop이 없다.
8. 375×667에서 HUD, danger, player, drop이 겹치거나 색에만 의존하지 않는다.
9. 최소 기기 hard floor 30fps, target 60fps, 100ms 초과 hitch 0이다.
10. 같은 5명 A/B에서 Descent 자발적 3회차가 Return Shot보다 최소 1명 높고 재미 중앙값 ≥4/7이다.
11. 5명 중 4명이 도움 없이 5초 안에 기체를 선택하고 출격하며, 4명이 세 발사 패턴 중 두 개 이상을 설명한다.
12. 375×667과 402×874에서 세 카드, 닫기, 선택 상세, 출격 CTA가 겹치지 않고 각 터치 영역이 44pt 이상이다.
13. 같은 기체·seed·양자화 input은 30/60/120Hz에서 checksum과 projectile event가 동일하다.
14. 100-seed reference bot에서 기체별 score 중앙값 편차가 8% 이하이고 active projectile은 Trident volley를 포함해 24를 넘지 않는다.
15. 하단 reactor bar node는 0개이며, bar 제거 뒤에도 5명 중 4명이 2초 안에 drag를 시작한다.
16. tick 3600에서 정상 전투 처리가 먼저 끝나고 finish가 우선한다. Arena는 run당 한 번만 열리며 대기 중 state·entity·score·checksum이 불변이다.
17. 레드라인의 118% 속도와 기본 미사일 직접 파괴 135% 점수는 선택 다음 tick부터만 적용되고, Danger Save와 다섯 persistent effect의 damage·score는 변하지 않는다.
18. 같은 seed·ship·choice·양자화 input은 30/60/120Hz와 large-delta batch에서 checksum과 event가 동일하다.
19. 375×667과 402×874에서 heading, PB pace, 두 96pt 이상 선택 카드가 겹치지 않고 각 터치 영역이 44pt 이상이며, carried touch 오선택이 0건이다.
20. 5명 중 4명이 도움 없이 5초 안에 선택하고 `레드라인은 낙하 속도와 기본탄 점수만 올리며 스킬은 그대로`라고 설명한다.
21. direct projectile 파괴 8-chain의 `N-1/N/N+1`과 191/192/193-tick 경계가 정확하고, trigger tick에는 bonus 0, 다음 tick부터 360 ticks만 활성이다.
22. frenzy 중 direct hit은 매번 종료를 `current tick+360`으로 갱신하고, skill hit·비직접 파괴·VFX는 chain·종료 tick을 바꾸지 않는다.
23. frenzy와 레드라인 동시 적용은 base+combo의 +20%와 +35%를 가산하고, projectile·skill damage, persistent effect, drop, spawn, HP, Danger Save가 Revision 4 reference와 같다.
24. 같은 seed·ship·choice·양자화 input의 Revision 5 checksum/event/score/frenzy state가 30/60/120Hz와 large-delta batch에서 동일하다.
25. 5명 연구에서 active-touch 중앙값 ≥60%, 자발적 3회차 완료 ≥3/5, `score_run3 ≥ 1.20 × score_run1` 충족 ≥3/5다. 미시작·미완료는 실패로 센다.
26. 같은 seed·ship·choice의 100-seed reference에서 no-input score 중앙값은 active reference의 75% 이하이고, `FrenzyScoreShare` 중앙값은 20% 이하를 권고 상한으로 지킨다.

## Stop Conditions

- 2/5 이상이 `가만히 있어도 되는 자동 게임`이라고 평가하거나 active-touch <60%.
- 자발적 3회차가 Return Shot보다 높지 않음.
- 불공정 breach, unreachable drop, duplicate reward, VFX-origin miss가 1건이라도 발생.
- 2/5 이상이 경험한 스킬을 구분하지 못함.
- 2/5 이상이 기체 기본 미사일과 원소 스킬을 같은 성장 체계로 오해하거나, 기체 선택 중앙값이 5초를 넘음.
- 한 기체의 100-seed score 중앙값이 다른 기체보다 8% 넘게 우세하거나 Trident의 관통·3-lane 공격이 score를 비정상 증폭함.
- bar 제거 뒤 2/5 이상이 drag를 발견하지 못함.
- 2/5 이상이 Choice Arena를 원소 선택이나 영구 강화로 오해하거나 중단 자체를 짜증으로 평가함.
- carried touch 오선택 1건, 선택 중앙값 5초 초과, 레드라인 선택률 20% 미만 또는 80% 초과.
- 레드라인 bonus가 총점의 25%를 넘거나 특정 기체의 100-seed score 중앙값을 다른 기체보다 8% 넘게 유리하게 만듦.
- 3/5 이상이 고유한 위험-드롭 선택을 말하지 못하고 기존 자동 대포·세로 슈터 복제품으로만 인식.
- 미니보스·적 탄환·수동 cooldown·영구 meta를 넣어야만 재미가 생김.
- active-touch 중앙값 <60%, 자발적 3회차 완료 <3/5 또는 Run 3가 Run 1보다 20% 이상 높은 참가자 <3/5.
- 같은 seed·ship·choice reference에서 no-input score가 active reference의 75%를 초과해 직접조작의 기록 기여를 분리하지 못함.
- 100-seed reference의 `FrenzyScoreShare` 중앙값이 20%를 초과하거나 특정 기체·Choice만 bonus를 독점해 기존 8% 공정성 상한을 넘음.
- 8-chain·192-tick·next-tick·360-tick refresh 경계 또는 30/60/120Hz checksum이 한 건이라도 어긋남.

## Implementation Evidence — 2026-08-21 KST

- Revision 5 BREAK FLOW 권위 규칙과 표현 계층을 구현했다. 직접 projectile 파괴만 8-chain을 충전하고, 192-tick inclusive 경계·다음 tick 시작·360-tick frenzy·직접 파괴 refresh·기존 base 점수의 +20% 가산·레드라인과의 가산·Choice freeze·checksum 포함을 자동시험으로 고정했다.
- calm HUD는 `CHAIN N`과 8칸 충전 meter, frenzy HUD는 남은 시간과 누적 bonus를 표시한다. 시작 outline은 플레이 오브젝트를 가리지 않으며 결과·일시정지 화면에는 MAX CHAIN, 발동 횟수, bonus가 남는다. 새 버튼·모달·스킬 slot·영구 meta는 추가하지 않았다.
- SwiftPM authoritative core 70/70, iPhone 17 Pro Xcode unit·asset·analytics·report 97/97, 제품 UI 회귀 14/14가 통과했다. 별도 30초 영상 데모 1건은 환경 변수가 없으면 의도적으로 skip한다.

- 오너 제공 1448×1086 RGBA 시트 6개를 `DB_Objects`, `DB_BreakStates`, `DB_SkillItems`, `DB_SkillVFX`, `DB_PlayerAttacks`, `DB_HUD` asset으로 연결했다. 흰 배경 JPEG와 실제 alpha가 없는 ImageGen 편집 후보는 런타임에서 제외했다.
- 오브젝트·플레이어·투사체·drop·5속성 VFX는 typed `DescentArtCatalog` crop을 통해 표시하며, atlas crop 간 1px 안전 간격과 alpha 보존을 Xcode test로 검증한다.
- 결정론 규칙·spawn-plan·5 persistent effects·세 기체 loadout·Choice Arena·BREAK FLOW 계약을 포함한 SwiftPM 70/70 tests가 통과했다. pickup combat 0, immutable volley snapshot, 비소급 projectile, same-ID fire echo, recursive drop 0, 같은 기체·seed의 30/60/120Hz, Trident edge sliding window, Arena freeze, 레드라인 다음-tick, frenzy 경계·만료·점수 분리를 포함한다.
- `home → play → pause → resume → 60초 result → retry` UI flow는 iPhone 17 Pro와 375×667급 iPhone SE 양쪽에서 통과했다. 캡처는 `docs/screenshots/descent-2026-08-19/`에 보존한다.
- 최신 Xcode unit·asset tests 58/58과 375×667 UI evidence `home → 기체 선택 → Hammer 확정 → 해당 missile로 play → pause → result → 같은 기체 retry` 1/1이 통과했다. 하단 reactor bar는 제거되고 player ship만 남았다.
- Choice Arena 통합 뒤 Xcode unit·asset tests 64/64, 375×667 UI `Arena → 레드라인 → 재개 → 결과`와 기존 Descent full-flow 2/2, 402×874 Choice Arena flow 1/1이 통과했다. 실제 캡처에서 두 선택 카드와 결과 CTA의 clipping은 0건이다.
- Choice Arena research harness는 Debug opt-in `-descentResearch`로만 활성화한다. `-descentVariantNoArena`는 tick 3600의 Choice를 같은 fixed-tick loop에서 steady로 해소해 UI·시간 정지가 없고, 기본 variant는 기존 Arena를 유지한다. 연구 PB는 메모리에서 0으로 격리하며 일반 UserDefaults PB를 읽거나 덮어쓰지 않는다.
- 로컬 logger는 가명 participant slot, A/B order, run ID, seed, ship, active-touch·lane-change·선택·종료 event만 1MB/100-run 상한 JSONL로 upsert한다. 네트워크, 외부 SDK, raw touch 좌표, 사용자 신원과 정확한 접근성 설정은 수집하지 않는다.
- persistent-effects native adaptation을 포함한 Debug·Release generic iOS Simulator 앱 전체 빌드, SwiftPM core 61/61, iPhone 17 Pro Simulator Xcode unit·asset·research tests 88/88을 통과했다. 변경 뒤 `기체 선택→플레이→일시정지→결과→재시도`와 `Choice Arena→레드라인→결과` UI flow 2/2도 통과했다. pickup 이후 다섯 효과 visual과 실기기 성능은 아직 별도 수동 검증이 필요하다.
- 아직 통과하지 않은 Gate: 5명 A/B 이해·자발적 3회차, 실기기 10분 성능/발열, VoiceOver·Switch Control·최대 Dynamic Type, 공개·상용 사용권 확인.
- Choice Arena P01–P10 실사용 데이터는 0명이다. Revision 5 logger·terminal summary·CSV는 `schema_version=2`, `rulesVersion=descent-rev5-break-flow-frenzy-r1`, frenzy bonus·발동·active ticks·MAX CHAIN을 기록하며 다른 schema·rules version을 fail-closed로 배제한다. 다만 BF01–BF05 배정·5명 전용 report와 100-seed agency reference는 아직 구현·수행되지 않아 사용자 수집을 시작하지 않는다.
- `+15초` checkpoint는 체류시간을 직접 늘리지만 60초 record·자발적 재시도 분모를 바꾸므로 BREAK FLOW 판정이 끝날 때까지 **Defer**한다. 영구 meta power는 core 재미와 실력 기반 기록을 가리고 경제·콘텐츠 비용을 추가하므로 이번 slice에서 **Reject**한다.
- Conflict: 시장·Red Team은 초기 choice paralysis를 줄이기 위해 2기체 A/B를 권고했다. 오너의 명시 요청에 따라 로컬 slice는 3기체를 유지하되, 5명 테스트에서 선택 중앙값·패턴 설명 Gate를 실패하면 2기체로 축소한다.
