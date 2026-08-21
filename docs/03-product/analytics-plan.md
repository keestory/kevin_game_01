# Descent Breaker Revision 5 BREAK FLOW + Choice Arena A/B — Local Research Analytics Plan

> 상태: **REVISION 5 계약 승인 / 구현·사용자 연구 미실행**
>
> 기준일: 2026-08-20 KST
>
> 현재 단계: Stage 4 Solution Definition → Stage 5 Build Readiness
>
> 권위 제품 계약: `docs/product-specs/descent-breaker.product-spec.md` Revision 5
>
> 범위: 외부 SDK·서버·TestFlight 분석 없이 **로컬 research build**에서 수행하는 5명 BREAK FLOW 선행 Gate와 10명 Choice Arena 방향성 검증

이 문서의 모든 수치와 판정선은 시장 benchmark가 아니라 내부 연구 가설이다. 실제 사용자 테스트, 이벤트 완결성 QA, 보조기술 검증 전에는 BREAK FLOW나 Choice Arena가 체류·재도전·D1/D7을 개선했다고 주장하지 않는다. 2026-08-20 한국 iPhone Games 차트와 경쟁작 store description은 기능 선례일 뿐 이 효과의 인과 근거가 아니다.

## 1. 의사결정과 가설

### 순차 의사결정

1. Revision 5 BREAK FLOW 공통 core가 직접조작·기록 상승·자발적 3회차 최소 Gate를 넘는지 5명 단일군으로 먼저 판정한다.
2. 1번을 통과한 뒤 동일한 Revision 5 공통 core에서 60초 무중단 run과 30초 Choice Arena를 10명 counterbalanced A/B로 비교한다.

BREAK FLOW가 A/B 양쪽에 공통으로 들어가므로 2번 실험은 Arena의 증분만 추정하며 BREAK FLOW 자체 효과를 인과적으로 추정하지 않는다.

### 추적 가능한 가설

| ID | 가설 | 대상 | 행동 | 기대 결과 | 측정 | 실패 기준 |
|---|---|---|---|---|---|---|
| BF-H1 | 직접 파괴 8-chain 뒤 bounded frenzy가 기록 상승 행동을 만든다 | 한국 iPhone 캐주얼 액션 사용자 5명 | 같은 seed·ship으로 2회 필수 후 자유 재시도 | 자발적 3회차와 Run1→3 향상 | 5명 pre-Gate Primary | 자발적 Run3 또는 +20% 향상 <3/5 |
| BF-H2 | frenzy가 자동 관람이 아니라 drag 판단을 보강한다 | 같은 5명과 deterministic reference | 위험 lane 이동·직접 hit으로 frenzy 유지 | active-touch 유지, no-input 열세 | touch·no-input guardrail | touch <60% 또는 no-input >75% |
| CA-H1 | 30초의 명시적 위험 선택이 run의 주도감과 재도전 의향을 높인다 | 한국 iPhone 캐주얼 액션 사용자 | 안정 비행/레드라인 중 선택 | B에서 자발적 같은 패턴 재도전 증가 | Primary, agency·fun | B 재도전이 A보다 2명 이상 낮음 |
| CA-H2 | 두 선택의 차이를 5초 안에 이해한다 | B에서 Arena까지 도달한 참가자 | 카드만 보고 선택·설명 | 8/10 이상이 효과 범위를 정확히 설명 | comprehension, latency | 2명 이상이 원소 스킬/영구 강화로 오해 |
| CA-H3 | 중단과 선택이 기존 한 손 drag 리듬을 해치지 않는다 | 전체 참가자 | 선택 후 즉시 drag 재개 | active-touch·lane 변경·생존이 유지 | input·survival guardrail | active-touch <60% 또는 짜증 2명 이상 |

## 2. Variant 계약

한 번에 Choice Arena 유무만 바꾼다. 기체, seed, spawn/drop plan, projectile snapshot 기반 5속성 L0~L3, HP, 점수, 난이도, BREAK FLOW와 접근성 설정·기기 조건은 참가자 내에서 동일하게 고정한다. 5명 선행 Gate와 두 A/B variant의 `rulesVersion`은 반드시 `descent-rev5-break-flow-frenzy-r1`이어야 하며 Revision 4 또는 다른 버전의 run은 같은 판정에 섞지 않는다.

### Revision 5 공통 BREAK FLOW 계약

- 직접 projectile 파괴가 직전 qualifying 파괴 뒤 192 ticks 이내면 chain +1이며, 8번째 파괴 다음 tick부터 360 ticks frenzy가 활성화된다.
- 활성 중 direct projectile hit마다 종료를 `current tick+360`으로 갱신한다. skill hit·비직접 파괴는 chain·refresh에 관여하지 않는다.
- frenzy 중 direct projectile 파괴는 기존 base+combo points의 +20%를 가산한다. 레드라인 +35%와는 합산해 최대 +55%이며 곱하지 않는다.
- skill·projectile damage, persistent effects, drop, spawn, HP, Danger Save는 Revision 4 reference에서 불변이다.

| Variant | ID | 계약 |
|---|---|---|
| A — noArena | `DB_CA_A_REV5_NO_ARENA` | Revision 5 BREAK FLOW core를 유지하고 tick 3600에서 UI·권위 simulation을 멈추지 않는다. Choice 관련 이벤트는 0건이어야 한다. |
| B — choiceArena | `DB_CA_B_REV5_ARENA` | 같은 Revision 5 BREAK FLOW core에서 tick 3600 정상 transaction 뒤 simulation·시간을 정지하고 Arena를 1회 표시한다. 레드라인은 다음 tick부터 낙하·상대 delta 118%, 기본 미사일 직접 파괴 base+combo 점수 +35%이며 frenzy +20%와 가산된다. persistent effect·Danger Save·drop·HP는 불변이다. |

B의 레드라인은 의도적으로 후반 점수와 난이도를 바꾸므로 **최종 점수의 A/B 평균을 Primary로 사용하지 않는다.** 선택별 점수·생존은 공정성 guardrail로만 분리해 본다.

### 연구 빌드 고정 카피

- Heading: `남은 30초, 기록을 걸까요?`
- 안정 비행: `속도·점수 그대로\n생존을 이어갑니다`
- 레드라인: `낙하 속도 +18%\n기본 미사일 직접 파괴 +35%`
- Scope note: `원소 스킬·기체 성능·체력은 바뀌지 않습니다`
- PB 영역: 각 variant를 fresh profile로 시작하여 `현재 {score} · 첫 기록을 완성하세요`만 표시한다.

문구, 카드 순서, 350ms carried-touch guard는 B 참가자 모두에게 동일하다. 자동 선택과 제한시간은 없다.

## 3. 지표 정의

### BREAK FLOW 5명 선행 Gate — Primary 세 개

5명 모두 A `noArena`의 Revision 5 공통 core를 사용한다. run 1·2는 필수이고, 두 번째 결과 뒤 60 active seconds 동안 retry를 지시하지 않는다.

1. `Active-touch`: 참가자별 필수 run 1·2 중앙 `ActiveTouchRatio`의 그룹 중앙값이 60% 이상이다.
2. `자발적 3회차 완료`: 자유 창 안에 same-seed·same-ship retry를 스스로 선택하고 terminal까지 완료한 참가자가 3/5 이상이다. 미시작·미완료는 실패다.
3. `Run1→Run3 20% 기록 상승`: `score_run3 ≥ 1.20 × score_run1`을 충족한 참가자가 3/5 이상이다. run1 score 0, 3회차 미시작·미완료는 실패다.

이 5명 Gate는 작은 방향성 표본이며 baseline이 없는 D1/D7, 장기 체류, 한국 무료 1위를 증명하지 않는다.

### Choice Arena A/B Primary — 세 개만 사용

공통 파생값은 다음과 같다.

```text
ComparableScore = score - redline_bonus_score
ActiveTouchRatio = active_touch_ms / active_play_ms
FrenzyScoreShare = frenzy_bonus_score / score  // score=0이면 0
NoInputScoreRatio = median(no_input_reference_score) / median(active_reference_score)
```

1. `자발적 3회차 완료`: variant별 필수 2회가 끝난 뒤 60 active seconds 안에 참가자가 스스로 같은 seed 재시도를 탭하고 세 번째 run을 terminal까지 완료. B ≥6/10, paired uplift ≥20%p(최소 순증 2명)가 Pass다.
2. `Run1→Run3 비교점수 20% 상승`: ITT 참가자 10명 중 `자발적 3회차 완료`와 `ComparableScore_run3 ≥ 1.20 × ComparableScore_run1`을 모두 충족한 인원. 3회차 미시작·미완료·run1 점수 0 이하는 실패 0으로 유지한다. B ≥6/10, paired uplift ≥20%p가 Pass다. 레드라인 보너스를 포함한 총점 상승은 진단값일 뿐 성공 판정에 쓰지 않는다.
3. `Active-touch non-inferiority`: 필수 run 1·2의 참가자별 중앙 ActiveTouchRatio를 비교한다. B 중앙값 ≥60%, 참가자 내 paired delta 중앙값 ≥-5%p가 Pass다.

분석 단위는 run이 아니라 **참가자 10명**이다. 10명의 20%p는 사람 2명에 불과하므로 이 결과는 방향성 학습이며 D1/D7이나 한국 무료 1위를 증명하지 않는다.

`no_input_score_ratio`는 사용자 5명 점수와 비교하지 않는다. A `noArena`에서 사전 고정한 동일 100 seeds×3 ships에 대해 중앙 lane 고정 no-input trace와 결과를 보기 전에 동결한 deterministic active reference trace를 짝지어 계산한다. active reference 중앙 score가 0이면 비율을 만들지 않고 hard DQ invalid다. seed·ship별 numerator/denominator와 전체 중앙값을 함께 보고하며, 특정 기체의 실패를 전체 평균으로 숨기지 않는다.

### Driver

| 지표 | 정의 | Pass 후보 |
|---|---|---:|
| `choice_comprehension_rate` | B 선택 직후 유도 없이 “레드라인은 낙하와 기본탄 직접 파괴 점수만 올리고 스킬·HP는 그대로”라고 설명; Arena 미도달은 실패로 포함 | ≥8/10 |
| `choice_latency_ms` | B의 `choice_selected.activeLatencyMilliseconds`; background 시간을 제외한 scene 계측값 | 중앙값 ≤5,000ms |
| `result_to_retry_latency_ms` | 결과 노출부터 retry까지 background를 뺀 active wall time | 분포 보고 |
| `agency_rating_7pt` | “내 선택이 후반 플레이를 바꿨다” 1–7 | B 중앙값 ≥4 |
| `fun_rating_7pt` | run 직후 재미 1–7 | B 중앙값 ≥4, A 대비 paired 중앙 차이 ≥0 |
| `redline_selection_rate` | B 유효 선택 중 redline | 20–80% |
| `arena_reach_rate` | B run 중 생존 상태로 tick 3600 도달 | ≥9/10 |
| `frenzy_exposure_rate` | 60초 run에서 frenzy가 1회 이상 발동한 참가자 / 전체 참가자 | 분포 보고; <3/5면 BREAK FLOW 가설 노출 부족으로 Revise |
| `frenzy_active_ticks` | run에서 frenzy active였던 authoritative ticks; refresh 중복 없이 합집합 | 분포 보고 |

### Guardrail

| 지표 | 정의 | 중단/재작업선 |
|---|---|---|
| `active_touch_ratio` | playing wall time 중 유효 drag touch가 활성인 시간 / playing wall time; Arena 정지시간 제외 | B 중앙값 <60%면 Stop |
| `meaningful_lane_changes_per_min` | 새 nearest lane에서 15 authoritative ticks 유지된 변경 횟수 / playing minute | B 중앙값 20–40 밖이면 Revise |
| `arena_annoyance_count` | “게임 흐름을 끊어 짜증났다” 자발 진술 또는 annoyance ≥5/7 | ≥2/10이면 Stop |
| `carried_touch_misselection` | overlay 진입 전 touch가 선택으로 accepted된 건 | 1건이면 Stop |
| `reactor_survival_rate` | 60초 생존 참가자 / variant 결과 참가자 | B가 A보다 3명 이상 낮으면 Stop |
| `redline_bonus_share` | redline bonus / 최종 점수 | 100-seed reference에서 25% 초과 또는 기체 편차 8% 초과면 Stop |
| `frenzy_score_share` | `frenzy_bonus_score / score`; score=0이면 0 | 같은 100-seed active reference의 중앙값 20% 초과면 Stop |
| `no_input_score_ratio` | 같은 rulesVersion·seed·ship·choice에서 no-input reference 중앙 score / active reference 중앙 score | 75% 초과면 Stop |
| `accessibility_task_success` | 보조기술 표본이 Arena 인지→선택→drag 재개를 도움 없이 완료 | 실패 1건은 P1 Revise, 선택 불능은 P0 Stop |

## 4. Event taxonomy

### 공통 속성

| 속성 | 형식 | 정의 | PII/민감도 |
|---|---|---|---|
| `schema_version` | Int | Revision 5 envelope는 `2`; Revision 4 schema 1을 변환·혼합하지 않음 | 없음 |
| `research_session_id` | random UUID | 로컬 연구 세션 단위 | 가명 연구 식별자 |
| `participant_slot` | `BF01`…`BF05` 또는 `P01`…`P10` | 동의서 이름과 분리된 연구 번호 | 가명 연구 식별자 |
| `variant_id` | enum | A 또는 B의 고정 ID | 없음 |
| `sequence` | enum | `BF_SINGLE` / `AB` / `BA` | 없음 |
| `run_id` | random UUID | variant 내 run | 없음 |
| `rulesVersion` | String | 정확히 `descent-rev5-break-flow-frenzy-r1` | 없음 |
| `seed_id` | bounded enum | 사전 승인한 로컬 research seed | 없음 |
| `ship_kind` | enum | Swift/Hammer/Trident | 없음 |
| `device_class` | enum | `375x667` / `402x874` | 없음 |
| `monotonic_ms` | Int | 세션 시작 기준 경과시간; 절대시각 아님 | 없음 |

정확한 OS accessibility 설정은 runtime event로 수집하지 않는다. 보조기술 참여 여부는 명시적 동의를 받은 facilitator observation sheet에만 broad cohort로 기록한다.

### 런타임 이벤트

| Event | 정확한 발생 조건 | Event 전용 속성 | PII | 기대 횟수 |
|---|---|---|---|---:|
| `research_variant_assigned` | 별도 event가 아니라 각 envelope의 immutable context로 저장 | `participant_slot`, `variant`, `order_index`, `seed`, `ship`, `best_score_before` | 없음 | run당 1 context |
| `descent_run_started` | phase가 playing이 되고 첫 authoritative tick 직전 | `initial_hp`, `best_score=0` | 없음 | run당 1 |
| `descent_first_input` | 최초 유효 drag가 양자화 player X 또는 lane을 바꿈 | `elapsed_tick`, `from_lane`, `to_lane` | 없음; raw 좌표 금지 | run당 ≤1 |
| `choice_presented` | B가 tick 3600 transaction 완료 후 awaiting choice로 전환 | `presented_tick=3600`, `score_at_30`, `reactor_hp` | 없음 | B 생존 run당 1, A는 0 |
| `choice_selected` | 350ms guard 뒤 새 tap의 선택이 authoritative state에 accepted | `choice`, `latency_ms`, `score_at_30`, `reactor_hp` | 없음 | presented당 1 |
| `descent_run_finished` | 60초 생존 또는 reactor 0 결과가 확정 | `end_reason`, `score`, `duration_ticks`, `max_combo`, `danger_saves`, `active_touch_ms`, `meaningful_lane_changes`, `arena_choice`, `redline_bonus_score`, `frenzy_bonus_score`, `frenzy_trigger_count`, `frenzy_active_ticks`, `max_direct_chain` | 없음 | started당 1 |
| `descent_retry_selected` | 필수 run 2 결과 뒤 열린 60 active seconds 자유 창에서 same-seed retry CTA가 accepted | `active_milliseconds_after_result`, `same_seed=true`, `same_ship=true` | 없음 | optional window당 0…1 |
| `optional_retry_window_opened` | 필수 run 2 terminal 직전에 60초 자유 재도전 창을 선언 | `duration_ms=60000` | 없음 | variant run 2당 1 |
| `research_post_run_recorded` | 앱 event가 아닌 facilitator observation CSV에 기록 | `fun_7pt`, `agency_7pt`, `annoyance_7pt`, `comprehension_code`, `prompt_count`, `input_mode` | 가명 연구 데이터 | variant당 1 |

`choice_latency`는 별도 이벤트로 중복 기록하지 않는다. 현재 schema에는 `choice_presented`의 monotonic timestamp가 없으므로 `choice_selected.activeLatencyMilliseconds`만 사용한다. ±16ms 독립 재계산은 schema revision 전까지 P1 gap이며 이번 10명 Gate의 hard DQ 조건으로 쓰지 않는다.

수집 금지: 이름, 전화번호, 이메일, Apple ID, 광고 ID, IP, 연락처, 공유 대상, 음성 녹음 원문, 자유입력 전문, raw touch 좌표, 정확한 OS 접근성 설정, crash stack의 로컬 경로·비밀.

## 5. Research protocols

### 5명 BREAK FLOW 선행 Gate

- Choice confound를 제거하기 위해 5명 모두 A `noArena`, `rulesVersion = descent-rev5-break-flow-frenzy-r1`을 사용한다.
- 각 참가자는 같은 ship·seed로 run 1·2를 필수 수행한다. run 2 결과 뒤 60 active seconds의 자유 창을 열되 retry·고득점 방법·frenzy 조건을 지시하지 않는다.
- run 3은 참가자가 스스로 retry하고 terminal까지 완료한 경우만 인정한다. run1 score 0, run3 미시작·중단은 Run1→3 성공 0이다.
- active-touch, 자발적 run3, Run1→3 +20%, frenzy 노출·점수 share, “자동으로 봐도 된다”는 자발 진술을 참가자 단위로 보고한다.
- 사용자 세션 전에 100-seed no-input/active reference, 8-chain `N-1/N/N+1`, 191/192/193-tick, next-tick 360-tick, 30/60/120Hz checksum을 통과해야 한다.
- 이 5명은 후속 10명 Choice Arena A/B 표본에 재사용하지 않는다. BREAK FLOW 조건을 이미 학습한 참가자는 Arena 증분을 과대·과소 추정할 수 있다.

### 10명 Choice Arena Counterbalanced protocol

#### 표본과 순서

- 총 10명. 한국어를 사용하는 iPhone 캐주얼 게임 사용자 8명, Larger Text/Reduce Motion 사용 경험자 1명, VoiceOver 또는 Switch Control 실제 사용자 1명을 모집 목표로 한다. 실제 모집 결과는 `미확인`으로 보고한다.
- P01–P05는 A→B, P06–P10은 B→A. 각 5명 안에서 research seed와 기기 class를 균형 배정한다.
- 참가자는 첫 variant 전에 기체 하나를 직접 선택하고 두 variant에서 같은 기체를 사용한다.
- 실험 전에 Arena 없는 별도 seed로 최대 20초의 공통 drag·자동 발사 familiarization 1회만 제공한다.

#### Variant별 절차

1. 앱 데이터와 PB를 초기화한 fresh profile을 확인한다.
2. 사전 배정된 같은 seed·기체·기기·접근성 조건으로 variant를 시작한다.
3. 설명 없이 60초 또는 조기 사망까지 플레이한다. Moderator는 입력·선택을 돕지 않는다.
4. 동일 variant에서 run 1·2는 필수로 수행한다. 두 번째 결과 뒤에는 중립적으로 자유 플레이 시간을 열되 retry를 지시하지 않는다. 60 active seconds 안의 자발적 retry와 세 번째 run terminal 완료만 Primary로 인정한다.
5. 즉시 fun·agency·annoyance 1–7과 “무엇이 달라졌나”를 묻는다. B에서는 선택 효과를 자유 설명하게 하며 정답을 먼저 말하지 않는다.
6. 해당 variant block이 끝난 뒤 profile/PB를 초기화하고 다른 variant로 이동한다. 두 block 종료 후 A/B 선호, 이유, 흐름 중단 인식을 묻는다.

Variant 순서, seed, ship, device, Arena 도달 여부와 moderator prompt는 반드시 원자료에 남긴다. Arena에 도달하지 못한 B 참가자를 조용히 제외하지 않고 intent-to-treat와 reached-Arena를 함께 보고한다.

## 6. PB 30초 비교 오류와 PB Pace Rival 분리 조건

### 현재 오류 — P0 experiment validity blocker

현재 Revision 3 UI의 `descentChoicePaceText`는 30초의 `snapshot.score`를 60초 종료 시점의 `bestScore`와 비교해 `PB까지 N점`이라고 표시할 수 있다. 시간축이 다른 값을 비교하므로 실제 pace가 아니며, B에만 불리한 압박·혼란을 추가하는 confound다.

Choice Arena A/B에서는 다음을 모두 지킨다.

1. 각 variant를 `best_score=0` fresh profile로 시작한다.
2. B에는 `현재 {score} · 첫 기록을 완성하세요`만 표시한다.
3. 최종 PB, PB gap, pace 효과를 Primary·Driver에서 제외한다.
4. 위 조건을 재현하지 못하면 A/B를 실행하지 않는다.

### 후속 PB Pace Rival 진입 조건

PB Pace Rival은 Choice Arena A/B와 동시에 켜지 않고 별도 단일변수 실험으로 진행한다. 최소 선행 조건은 다음과 같다.

- 이전 최고 run의 authoritative score trace를 0–60초 1초 간격으로 저장한다.
- 현재 tick과 **동일한 경과 초**의 이전 score만 비교한다. 30초 값과 최종 60초 BEST를 비교하지 않는다.
- `rulesVersion + seed_id + ship_kind`가 일치하는 trace만 eligible하다. 없으면 `FIRST RUN`을 표시한다.
- 15·30·45·60초 checkpoint의 ahead/behind 값이 저장 trace와 일치하는 단위·UI 검증을 통과한다.
- PB 시각 신호는 점수·위험·drop을 가리지 않고 색 외에 `▲/▼/—`와 텍스트를 사용한다.
- VoiceOver는 매초 값을 읽지 않고 15·30·45초와 결과에서만 요약한다.

### 후속 체류·meta 기능 분리

- `60초 결과 → +15초 checkpoint/continue`는 active play time을 직접 바꾸고 자발적 3회차의 기회·분모를 흔드므로 BREAK FLOW와 동시에 켜지 않는다. BREAK FLOW 5명 Gate와 Choice A/B가 끝난 뒤 별도 rulesVersion·별도 실험으로만 **Defer**한다.
- 영구 meta power는 run 밖 누적 우위를 만들어 Run1→3 기록 상승이 학습인지 power인지 분리할 수 없고 경제·콘텐츠·밸런스 범위를 추가한다. 이 vertical slice에서는 **Reject**한다.
- 광고·부활·재화·결제는 두 연구 모두 0이어야 한다.

## 7. Pass / Revise / Stop

### BREAK FLOW 공통 core Pass

다음을 모두 충족해야 후속 10명 Choice Arena A/B를 시작한다.

1. 5명 active-touch 중앙값 ≥60%다.
2. 자발적 3회차 완료 ≥3/5다.
3. `score_run3 ≥ 1.20 × score_run1` 충족 ≥3/5다.
4. 100-seed×3-ship no-input score ratio가 전체와 각 ship에서 75% 이하이고 frenzy score share 중앙값이 20% 이하다.
5. projectile·skill damage, persistent effects, drop, spawn, HP, Danger Save가 Revision 4 reference와 같고 8-chain·192/360-tick·next-tick·30/60/120Hz DQ 오류가 0건이다.

frenzy 노출이 3/5 미만이면 체류 효과를 Pass/Fail로 단정하지 않고 **Revise**한다. chain threshold 또는 seed pattern 중 하나만 바꿔 재검증하며 기능을 더 추가하지 않는다.

### BREAK FLOW 즉시 Stop

- active-touch <60%, 자발적 3회차 <3/5 또는 Run1→3 +20% 충족 <3/5다.
- no-input score ratio >75% 또는 frenzy score share >20%다.
- 2/5 이상이 `가만히 봐도 되는 자동 게임`이라고 평가한다.
- frenzy·redline 합산, 기체별 score 편차 또는 persistent effect가 기존 공정성·25% skill contribution 상한을 넘는다.
- 8-chain·191/192/193-tick·next-tick 360-tick refresh·checksum·불변 계약 오류가 1건이라도 발생한다.

### Choice Arena 유지 Pass

BREAK FLOW 공통 core가 먼저 Pass하고, 다음을 모두 충족해야 한다.

1. B 자발적 3회차 완료와 Run1→Run3 비교점수 20% 상승이 각각 6/10 이상이며 A보다 최소 2명 높다.
2. B ActiveTouchRatio 중앙값 ≥60%, paired delta 중앙값 ≥-5%p다.
3. Choice comprehension ≥8/10, 선택 latency 중앙값 ≤5초다.
4. B fun·agency 중앙값이 각각 ≥4/7이고 A보다 paired 중앙값이 낮지 않다.
5. B Arena reach ≥8/10, redline 선택 20–80%이며 Guardrail Stop과 event DQ 오류가 0건이다.

Primary가 동률이거나 +1명에 그치되 Stop이 없으면 **Revise**다. 카피·중단 시점·후반 배수를 한 번에 하나만 바꿔 재검증한다.

### 즉시 Stop / Arena 제거 후보

- B 자발적 3회차 완료 또는 20% 비교점수 상승이 6/10 미만이거나 paired uplift 20%p 미만이다.
- 2/10 이상이 Arena를 원소 스킬·영구 강화로 오해하거나 흐름 중단을 annoyance ≥5/7로 평가한다.
- carried-touch 오선택 1건 또는 보조기술로 선택 불능 1건이 발생한다.
- B active-touch 중앙값 <60%, paired delta <-5%p 또는 60초 생존자가 A보다 3명 이상 적다.
- redline 선택이 20% 미만/80% 초과하거나 reference simulation에서 bonus share >25%·기체 score 편차 >8%다.
- PB 오류가 노출되거나 A/B 간 seed·ship·difficulty·카피 외 조건이 달라진다. 이 경우 제품 결론이 아니라 **실험 무효**로 판정한다.
- 한쪽이라도 `rulesVersion != descent-rev5-break-flow-frenzy-r1`, schema 1, Revision 4 envelope이거나 A/B의 frenzy 계약·reference output이 다르면 **실험 무효**다.

## 8. Data Quality 및 Privacy Gate

### Local-only architecture

- 외부 analytics·광고·crash SDK를 설치하지 않는다.
- 네트워크 endpoint와 자동 upload를 두지 않는다.
- append-only JSONL을 앱 sandbox 또는 XCTest attachment에 기록하고 연구자가 로컬에서만 집계한다.
- 원시 로그는 Gate 판정 후 최대 30일 보관하고 삭제한다. 비식별 aggregate와 Decision Log만 남긴다.
- 동의서·연락처와 `participant_slot`의 대응표는 앱 로그·저장소와 분리한다.

### 완결성 검사

- 모든 Revision 5 envelope는 `schema_version=2`와 `rulesVersion=descent-rev5-break-flow-frenzy-r1`을 가져야 한다. schema 1, Revision 4, 빈 값, unknown version은 변환하거나 묵시적으로 제외하지 않고 hard DQ invalid로 남긴다.
- `descent_run_started`마다 정확히 하나의 `descent_run_finished`가 있거나 명시적 연구 중단 사유가 있다.
- A의 `choice_presented`/`choice_selected`는 0건이다.
- Arena까지 도달한 B는 `choice_presented` 1건과 accepted `choice_selected` 1건이며 순서가 보장된다.
- `choice_selected.activeLatencyMilliseconds`는 0 이상이며 background 체류를 제외한다. 별도 monotonic 재계산은 현 schema에서 미지원이므로 수집 시작 전에 이 한계를 연구 기록에 남긴다.
- BF participant는 세 run에 같은 seed·ship·device class를 사용한다. Choice participant는 A/B에 같은 seed·ship·device class를 사용하고 sequence는 5:5다.
- PB는 variant 시작 때 0이며 `best_score=0` assertion 실패 세션은 제외가 아니라 invalid로 표시한다.
- terminal의 `frenzy_bonus_score`는 0 이상·score 이하이고 `frenzy_trigger_count`, `frenzy_active_ticks`, `max_direct_chain`은 음수가 아니다. derived `FrenzyScoreShare`는 원자료와 일치해야 한다.
- 필수 event 누락·중복은 각각 0건이고 `schema_version`·`rulesVersion`으로 재생성 가능해야 한다.
- UI test·developer traffic처럼 유효한 `participant_slot`과 `order_index`가 없는 envelope는 연구 집계에 포함하지 않는다.
- 집계 전 두 사람이 2개 세션을 원시 로그→summary로 독립 대조하고 차이 0을 확인한다.
- 현재 P01–P10 사용자 envelope는 0건이다. Revision 5 수집을 시작하기 전 0건 상태를 export로 고정하고 이후 Revision 4 traffic이 발견되면 혼합 분석을 하지 않는다.

## 9. 실행 방법과 현재 Gate

Debug research build에서만 다음 argument를 사용한다.

```text
-descentResearch -descentVariantNoArena -descentParticipant BF01 -descentOrderIndex 1
-descentResearch -descentVariantNoArena -descentParticipant P01 -descentOrderIndex 1
-descentResearch -descentParticipant P01 -descentOrderIndex 2
-descentResearch -descentParticipant P06 -descentOrderIndex 1
-descentResearch -descentVariantNoArena -descentParticipant P06 -descentOrderIndex 2
-descentResearchConsole
```

- BREAK FLOW 선행 Gate는 별도 namespace `BF01`…`BF05`, A `noArena`, order index 1만 사용한다. 현재 logger의 P01–P10 전용 검증을 넓히기 전에는 이 세션을 시작하지 않는다.
- 기본 research variant는 B `choiceArena`, `-descentVariantNoArena`는 A다.
- Choice A/B participant는 `P01`…`P10`, order index는 `1` 또는 `2`만 허용한다. BREAK FLOW pre-Gate는 `BF01`…`BF05`, order index 1만 허용한다.
- P01–P05는 A(no-Arena)→B(Choice), P06–P10은 B→A만 허용하며 잘못된 조합은 게임 시작 전에 차단한다.
- participant별 seed는 날짜와 무관한 고정값을 사용해 A/B가 다른 날 실행돼도 동일성을 유지한다.
- run 시작, Choice 제시·선택, terminal과 result action마다 같은 run ID를 upsert한다. 시작만 있고 terminal이 없는 envelope는 숨기지 않고 DQ 실패로 남긴다.
- 원본 JSONL에 손상·future-schema line이 하나라도 있거나 100 runs/1MB 상한에 도달하면 저장과 다음 연구 run을 차단한다. 기존 행을 자동 삭제하거나 정상 행만으로 재작성하지 않는다.
- `-descentResearchConsole`은 Primary, DQ, 다음 배정, P01–P10 상태, CSV export와 확인형 전체 삭제를 제공한다. 제품 게임 route·점수·profile은 변경하지 않는다.
- facilitator 절차와 삭제·내보내기는 [Choice Arena Research Runbook](../07-operations/choice-arena-research-runbook.md)을 따른다.
- 일반·Release 실행은 logger가 비활성화되며 외부 endpoint와 SDK가 없다.

**Revision 4 historical readiness: GO.** no-Arena variant, fresh PB 격리, local bounded logger, event exactly-once·terminal ordering·PII 금지·checksum 비영향 단위시험과 Choice lifecycle/carry-touch/no-Arena UI 회귀는 Revision 4에서 구현됐다.

**Revision 5 Implementation Gate: GO.** 권위 core, Scene/HUD, `rulesVersion = descent-rev5-break-flow-frenzy-r1`, schema 2, frenzy terminal fields·CSV와 fail-closed version 검증을 구현했다. SwiftPM 70/70, Xcode unit·asset·analytics·report 97/97, 일반 제품 UI 회귀 14/14가 통과했다.

**Revision 5 Data Readiness Gate: REVISE.** 현재 실행 배정은 P01–P10 Choice A/B 계약만 강제한다. BF01–BF05 전용 배정·single-group report, 100-seed active/no-input reference와 facilitator export 검증 전에는 BREAK FLOW 사용자 세션을 시작하지 않는다. 자동시험 통과는 참가자 증거가 아니다.

**Problem Validation Gate: REVISE.** 5명 BREAK FLOW 선행 Gate와 10명 counterbalanced A/B·보조기술 표본은 아직 실행되지 않았다. UX Research/Accessibility가 세션을 수행하고 Data & Experimentation이 참가자 단위 raw count, Primary와 Stop guardrail을 판정하기 전 BREAK FLOW·Choice Arena 유지, 체류·retention 개선, 한국 무료 1위 가능성을 주장하지 않는다.
