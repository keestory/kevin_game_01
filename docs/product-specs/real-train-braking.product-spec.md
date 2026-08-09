---
spec_format_version: "0.1"
title: "문 닫습니다! 지옥철 — 한국 iPhone crowd-timing challenger"
artifact_type: "hypothesis"
spec_revision: 3
author: "Product Orchestrator"
created_at: "2026-08-09T12:30:00Z"
updated_at: "2026-08-09T13:38:00Z"
linked_github_repo: "keestory/kevin_game_01"
---

## Problem

한국 사용자가 매일 겪는 혼잡 지하철은 즉시 알아보는 소재지만, 기존 prototype들은 열차를 배경으로만 쓰고 추상 제동 또는 문양 매칭을 시켜 실제 열차·문·군중의 긴장과 쾌감을 게임 규칙으로 만들지 못했다.

## Hypothesis

역마다 `출발 목표 인원`을 보여 주고, 문이 열리면 2.5D 사람들이 불규칙한 덩어리로 우르르 내리고 타며, 플레이어가 현재 탑승 인원이 목표와 맞는 순간 큰 `문 닫기` 레버를 누르게 하면, 문양 맞추기보다 3초 안에 규칙을 이해하고 타이밍·카운팅·지옥철 판타지 때문에 세 번째 운행을 더 자발적으로 시작할 것이다.

## Product Summary

`문 닫습니다! 지옥철`은 5개 역을 약 60초 동안 운행하는 세로형 원탭 군중 타이밍 게임이다. 각 역은 안전을 위해 자동 하차를 먼저 끝낸 뒤 탑승만 진행하며, 승객이 실제 네 문을 통과할 때 현재 인원이 단조 증가한다. 목표 인원과 정확히 같을 때 문을 닫으면 정확 출발, 한 명 차이는 안전 출발, 그 이상은 빈차 또는 초만원 판정이다. 초반은 한 명씩, 중반부터 탑승 간격과 시각적 군중 밀도가 빨라진다.

## Scope

```productspec-scope
in:
  - Include an original fixed-camera 2.5D train, four animated doors, platform crowd, fictional Korean night city, and one large close-door control.
  - Include five deterministic stations with different starting and target onboard counts and recoverable, solvable passenger-flow pulses.
  - Update the authoritative onboard count only when each visible passenger crosses a door threshold.
  - Include an easy first station, automatic alighting before monotonic boarding, denser later stations, clear exact and near feedback, free retry, sound, haptics, Reduce Motion, and lifecycle safety.
  - Include Product Harness evidence and equal-fidelity comparison against prior brake and routing prototypes before scale.
out:
  - Do not keep destination-symbol door selection as the primary loop.
  - Do not depict or reward jumping onto a moving train, obstructing real doors, trapping a person in a door, or unsafe platform behavior.
  - Do not use a real railway brand, station, train livery, announcement, landmark, or owner reference image as a runtime asset.
  - Do not claim Korean App Store rank 1, retention, or unit economics before measured evidence.
  - Do not ship forced ads, ad-gated solvability, pay-to-pass capacity, or friend install and signup bounties.
cut:
  - Cut boarding pulse complexity and use one-by-one boarding if variable cadence fails 5-second understanding.
  - Cut crowd density, particles, and parallax before reducing threshold clarity or frame stability.
  - Cut rewarded undo unless no-ad retention and policy gates pass first.
```

## User Experience

- 역 진입: `현재 18명 → 목표 14명`이 큰 숫자로 표시되고 문이 열린다.
- 흐름: 자동 하차가 끝나면 탑승 인원이 한 명씩 단조 증가한다. 첫 역은 느리고, 이후 역은 탑승 간격과 문별 시각 밀도가 빨라지되 모든 plan은 목표 인원을 반드시 지난다.
- 입력: 현재 인원이 목표와 같다고 판단한 순간 하단의 큰 `문 닫기` 레버를 탭한다.
- 판정: 정확하면 문이 닫히며 success haptic·차임·출발 효과, ±1은 안전, 그 이상은 `2명 초과` 또는 `3명 부족`을 설명한다.
- 실패: 무료로 같은 승객 흐름을 즉시 다시 볼 수 있다. 광고는 첫 세 운행과 핵심 재시도에 없다.

시각 기준은 `docs/04-design/concepts/platform-routing-diorama-concept-v2.png`의 품질·깊이만 승계한다. 목적지 문양 루프와 오너가 기각한 평면 화면은 실패 증거이며 런타임 계약이 아니다.

## Customer Truth

- 프로젝트 오너는 제동 prototype을 그래픽·효과·열차 인과 부족으로, 목적지 문양 prototype을 실제 게임성이 없다고 각각 기각했다.
- 오너는 지나가는 열차 입장 타이밍과 지옥철의 역별 인원수·문닫기 타이밍을 제안했고, 후자는 실제 문·군중·인원 수를 하나의 원탭 인과로 연결한다.
- crowd-flow 경쟁작의 다운로드는 소재 획득 proxy일 뿐 이 exact-count timing loop의 한국 iPhone retention 증거가 아니다.
- 목표 사용자 관찰, D1, D7, 한국 CPI, LTV, organic lift, 필요한 일간 설치량은 아직 Unknown이다.

## Solution Alternatives

1. 정차선 제동 rev1: 설명은 쉽지만 군중과 문이 결과 애니메이션에 그쳐 기각됐다.
2. 목적지 문양 라우팅 rev2: 비주얼은 개선됐지만 열차가 색상 매칭 skin에 머물러 기각됐다.
3. 지나가는 열차에 승객 넣기: 타이밍은 분명하지만 위험 행동을 연상시키고 승객 수 전략이 약해 제외한다.
4. 지옥철 목표 정원 문닫기 rev3: 실제 열차·문·군중·타이밍·카운팅이 같은 규칙에 참여해 현재 채택한다.

## Acceptance Criteria

```productspec-acceptance-criteria
- id: AC-1
  criterion: The primary frame shows a front-left 2.5D train, four doors, at least twelve visible or pooled commuters, platform depth, current onboard count, target onboard count, and one dominant close-door control without a brake bar or destination-door selector.
- id: AC-2
  criterion: A deterministic five-station plan starts forgiving and increases difficulty through automatic-alighting size, boarding cadence, and simultaneous-door visual density while every first-station target is held for at least 1200 milliseconds and every later target for at least 600 milliseconds.
- id: AC-3
  criterion: The authoritative onboard count changes only when a corresponding visible passenger crosses an open door threshold, and audit totals equal start plus boarded minus exited at every frame and station result.
- id: AC-4
  criterion: Closing at exact target yields perfect, at one passenger difference yields safe, and all other differences yield an explicit surplus or shortage result; one input produces exactly one result and doors never close through a passenger.
- id: AC-5
  criterion: The first successful close starts the scored clock, five stations are playable within a nominal 60-second run, and free deterministic retry never requires an ad, purchase, or friend action.
- id: AC-6
  criterion: Sound and haptics can be disabled independently, backgrounding pauses without auto-resume, and Reduce Motion replaces crowd movement with threshold-safe crossfades without hiding direction, count, or door state.
- id: AC-7
  criterion: Independent users achieve 5 of 5 two-second train recognition, at least 4 of 5 five-second explanation of closing at the target count, at least 8 of 10 unassisted first closes, median fun at least 4 of 7, liveliness at least 5 of 7, and at least 3 of 5 voluntary third runs.
- id: AC-8
  criterion: Minimum-device performance averages at least 55 fps with p95 frame time at most 22 milliseconds, no hitch above 100 milliseconds, no passenger or node leak over ten runs, and resident textures within the approved budget.
- id: AC-9
  criterion: Rule, deterministic-clock, threshold-crossing, duplicate-input, lifecycle, renderer-contract, UI close-door, ProductSpec, secret, and unsigned simulator build checks pass on a clean commit.
- id: AC-10
  criterion: Every runtime asset has provenance, commercial-use basis, hash, edit history, and similarity review, and no unsafe-action celebration or real railway identifier is shipped.
- id: AC-11
  criterion: A TestFlight candidate passes a 30-minute minimum-device soak with no crash, thermal failure, progression corruption, count mismatch, door intersection, or inaccessible core action.
- id: AC-12
  criterion: Korean App Store submission does not start until signing, privacy, age rating, support URL, screenshots, metadata, analytics, review notes, rollback owner, and business validation gates are confirmed.
```

## Success Metrics

```productspec-success-metrics
- id: SM-1
  metric: unassisted_first_close
  target: ">= 8 of 10 target users"
  target_status: committed
  window: moderated prototype test
- id: SM-2
  metric: exact_or_safe_station_rate
  target: ">= 80% first run and 65% final two stations"
  target_status: provisional
  target_owner: "Game Design"
  window: first three no-ad runs
- id: SM-3
  metric: voluntary_third_run
  target: ">= 40% directional cohort; powered threshold after baseline"
  target_status: provisional
  target_owner: "Product Orchestrator"
  window: no-ad prototype cohort
- id: SM-4
  metric: day_one_retention
  target: ">= 30% provisional; recommit after baseline and MDE calculation"
  target_status: provisional
  target_owner: "Growth and Analytics"
  window: no-ad TestFlight cohort
- id: SM-5
  metric: day_seven_retention
  target: ">= 10% provisional; recommit after baseline and MDE calculation"
  target_status: provisional
  target_owner: "Growth and Analytics"
  window: no-ad TestFlight cohort
- id: SM-6
  metric: crowd_timing_incremental_value
  target: "rev3 beats rev1 and rev2 on third-run or D1 without worse five-second understanding"
  target_status: committed
  window: equal-fidelity preregistered experiment
- id: SM-7
  metric: crash_free_sessions
  target: ">= 99.5%"
  target_status: committed
  window: launch-candidate TestFlight cohort
- id: SM-8
  metric: paid_acquisition_unit_economics
  target: "CPI <= observed D90 contribution LTV x 0.5 in two independent cohorts"
  target_status: committed
  window: post-launch limited Korean iOS campaign
```

## Adoption

1. 한국 통근자 12명 문제 인터뷰와 8명 5일 일기로 혼잡 경험·광고 피로·짧은 게임 맥락을 분리한다.
2. 10명 moderated test에서 숫자 주시, 첫 문닫기, 혼잡·멀미·안전 인식을 관찰한다.
3. 같은 완성도의 rev1/rev2/rev3 playable을 방향성 cohort로 비교하고 baseline·MDE에 따라 retention 표본을 산정한다.
4. no-ad TestFlight에서 D1/D7과 3회차를 먼저 측정한 뒤에만 opt-in `마지막 역 되돌리기`를 검증한다.
5. 한국 iOS 제한 소프트런치에서 실제 CPI/LTV·organic lift·필요 설치량을 학습한다.

## Pricing

첫 후보는 무료이며 핵심 진행과 모든 재시도는 광고 없이 가능하다. no-ad retention 통과 뒤에도 수익화는 실패 원인을 되돌리는 명시적 opt-in 한 가지부터 검증하고, 정답 타이밍·정원·해결 가능성은 판매하지 않는다.

## Risks

- 숫자만 보면 군중이 장식이 되고, 군중만 보면 목표 인원을 놓칠 수 있다.
- 큰 pulse가 목표를 건너뛰거나 threshold와 count가 어긋나면 공정성이 즉시 무너진다.
- 사람 사이로 문을 닫는 연출은 실제 안전 행동을 왜곡할 수 있다.
- crowd pooling·door layering·열·frame 비용이 작은 팀의 운영 한도를 넘을 수 있다.
- 지옥철 밈이 한국 획득에는 유리해도 글로벌 확장과 반복 retention에는 약할 수 있다.

## Open Questions

- 하차만 세는 첫 prototype과 승·하차 혼합 중 어느 쪽이 5초 이해와 세 번째 운행을 동시에 높이는가?
- 현재 인원 숫자를 계속 보여 줄지 pulse 순간에만 보여 줄지가 긴장과 공정성에 어떤 영향을 주는가?
- 지옥철 표현이 재미로 읽히면서도 불쾌·위험 연출로 보이지 않는 경계는 어디인가?
- 한국 무료 1위에 필요한 retained daily installs, CPI, organic multiplier, 예산은 얼마인가?

## Rollout

- Gate 0 — Problem discovery: 오너 직관이 아닌 목표 사용자 반복 문제 증거를 확보한다.
- Gate A — Prototype: AC-1~AC-6, AC-8~AC-10 통과.
- Gate B — UX validation: AC-7과 SM-1~SM-3 통과. 실패하면 pulse·정보 구조 또는 루프를 재설계한다.
- Gate C — Incrementality: SM-6 통과. rev3가 이기지 못하면 본개발을 중단한다.
- Gate D — TestFlight: AC-11, SM-4, SM-5, SM-7 통과.
- Gate E — Korean soft launch: AC-12 통과 후 제한 출시한다.
- Gate F — Scale: SM-8 통과 후에만 유료 UA와 라이브옵스를 확대한다.

## Business Validation Gate

현재 판정은 **Fail / Unknown**이다. 새 루프는 열차 인과와 첫 이해 가설이 더 강하지만 사용자 retention, 콘텐츠 비용, 한국 CPI/LTV, 필요한 설치량·예산은 아직 증거가 없다.

## Launch Stop Conditions

- 5초 안에 `목표 인원에서 문 닫기`를 4/5가 설명하지 못함.
- 한 역이라도 목표를 건너뛰는 impossible pulse 또는 450ms 미만 반응 창이 존재함.
- 보이는 threshold crossing과 onboard count가 한 명이라도 불일치하거나 문이 승객과 교차함.
- 첫 역 exact-or-safe가 80% 미만이거나 마지막 두 역이 65% 미만이면서 세 번째 운행이 개선되지 않음.
- 2/10 이상이 멀미·군중 혼란·불쾌한 안전 연출을 보고함.
- 최소 기기 55fps, 열, 메모리, 접근성, lifecycle, provenance Gate 중 하나라도 실패.
- 무료 재시도가 광고·결제보다 숨거나 광고 없이는 해결할 수 없음.
- 두 cohort에서 D1/D7 또는 CPI/LTV Gate를 실패하거나 콘텐츠·QA 비용이 승인 한도를 초과.

## Related Artifacts

```productspec-related-artifacts
- type: github_pr
  url: "https://github.com/keestory/kevin_game_01/pull/1"
  title: "Hell-train crowd timing challenger Draft PR"
  section_id: acceptance_criteria
  item_id: AC-1
- type: other
  url: "../04-design/concepts/platform-routing-diorama-concept-v2.png"
  title: "Diorama quality and depth reference; not runtime"
  section_id: acceptance_criteria
  item_id: AC-1
- type: experiment
  url: "../04-design/usability-test-report.md"
  title: "External validation evidence ledger"
  section_id: success_metrics
  item_id: SM-1
- type: engineering_spec
  url: "../05-engineering/architecture.md"
  title: "Native iOS architecture"
  section_id: acceptance_criteria
  item_id: AC-8
```
