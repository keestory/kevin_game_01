---
spec_format_version: "0.1"
title: "문을 맞춰라! 도시철도 — 한국 iPhone diorama challenger"
artifact_type: "hypothesis"
spec_revision: 2
author: "Product Orchestrator"
created_at: "2026-08-09T12:30:00Z"
updated_at: "2026-08-09T13:13:28Z"
linked_github_repo: "keestory/kevin_game_01"
---

## Problem

한국 iPhone 사용자는 짧은 시간에 이해되는 한 손 캐주얼 게임을 원할 수 있지만, 색상 분류 퍼즐의 반복성과 광고로 만든 불공정한 난이도에는 피로를 느낀다. 열차·플랫폼·군중이 실제로 반응하는 장난감 디오라마와 물리 레버가 이 문제를 개선할지는 아직 목표 사용자에게 검증되지 않았다.

## Hypothesis

첫 화면에 사선 원근 열차, 목적지별 승객 큐, 네 개의 문, 큰 좌우 레버를 함께 보여 주고, 사용자가 같은 색·문양의 문을 골라 실제 승하차를 일으키면, 기각된 평면 제동 게임보다 목표를 빨리 이해하고 세 번째 운행을 더 자발적으로 시작할 것이다.

## Product Summary

`문을 맞춰라! 도시철도`는 5개 역을 60초 동안 운행하는 세로형 목적지 분류 게임이다. 플레이어는 하단 레버로 네 개의 문 중 하나를 고르고 중앙 손잡이로 문을 연다. 올바른 문에서는 승객이 객실과 플랫폼 사이를 직접 이동하고 목적지별 진행이 채워진다. 현재 산출물은 출시 후보가 아니라 브레이크 A, 자동 정렬 B, 레버 C를 비교할 C 챌린저 vertical slice다.

## Scope

```productspec-scope
in:
  - Include an original fixed-camera 2.5D toy-diorama world with a front-left three-quarter train, platform crowd, four door bays, and fictional night city.
  - Include four destinations represented redundantly by original color, symbol, and Korean name.
  - Include a one-thumb left, open, and right lever interaction with equivalent accessibility actions.
  - Include visible train-to-platform and platform-to-train passenger movement through an open door.
  - Include five deterministic stations, ten recoverable queues, and a 60-second scored run after the first successful action.
  - Include free retry, pause and background safety, independent sound and haptics, Reduce Motion, Product Harness evidence, and A/B instrumentation.
out:
  - Do not retain the flat side-view train or brake timing bar as the primary C-variant gameplay.
  - Do not use the owner's reference image, a real railway logo, livery, station, landmark, character, map, announcement, or traced composition as a runtime asset.
  - Do not claim Korean App Store rank 1, retention, or unit economics before measured evidence exists.
  - Do not ship forced interstitials, ad-gated solvability, paid answer slots, or friend install and signup rewards.
  - Do not migrate to SceneKit, Unity, or another engine in this revision.
cut:
  - Cut the lever and test automatic alignment if lever C does not improve replay over automatic B.
  - Cut rewarded undo unless no-ad retention and policy gates pass first.
  - Cut parallax, particles, and crowd density before reducing input clarity, provenance, or frame stability.
```

## User Experience

- 0–2초: 전면·측면·지붕이 함께 보이는 열차, 플랫폼 큐, 네 문, 큰 레버로 상황을 인지한다.
- 2–5초: 현재 큐와 같은 문양의 문이 한 번 pulse하고 `같은 표식의 문을 골라 보내세요` coachmark가 첫 정답까지 유지된다.
- 선택: 좌우 36pt drag 또는 좌우 버튼으로 문을 한 칸 이동한다. 끝에서는 soft haptic만 나고 선택은 넘치지 않는다.
- 실행: 중앙 손잡이를 누르면 선택 문이 열린다. 정답이면 하차 후 탑승, 오답이면 `목적지가 달라요`와 문양 비교 후 같은 큐를 다시 시도한다.
- 결과: 목적지별 3명, 총 12명 완료가 성공 조건이며 점수와 콤보는 보조 피드백이다.
- 실패: 이유를 설명하고 광고 없는 `같은 운행 다시`를 항상 먼저 제공한다.

콘셉트 기준은 `docs/04-design/concepts/platform-routing-diorama-concept-v2.png`이며, 오너가 기각한 평면 화면은 `docs/screenshots/game-real-train-v1.png`에 실패 증거로 보존한다. 콘셉트 이미지는 런타임에 넣지 않는다.

## Customer Truth

- 2026-08-09 Apple 한국 무료 Games Top 25의 직접 인접작은 Bus Traffic Fever #11 한 편뿐이고, 직접군은 매출 Top 25에 없었다.
- Bus Jam, Bus Out, Seat Away, Crowd Express의 글로벌 Android 5M–10M+ 표시는 crowd-flow 획득 가능성의 proxy일 뿐 한국 iPhone retention 증거가 아니다.
- 경쟁작 리뷰에는 성취감·장기 레벨 이용과 함께 반복, 라운드 광고, 조기 난이도벽 불만이 공존한다.
- 프로젝트 오너는 rev1의 평면 측면 열차와 작은 제동 UI가 제공 레퍼런스의 3D 디오라마·군중·큰 레버와 다르다고 명시적으로 기각했다.
- D1, D7, 한국 CPI, LTV, organic lift, 목표 일간 설치량은 아직 Unknown이다.

## Solution Alternatives

1. A — 정차선 제동: 제작비와 설명성은 좋지만 반복 깊이가 얕을 수 있다. rev1 실패 증거와 코드 이력으로 보존한다.
2. B — 목적지 큐 자동 정렬: crowd-flow 자체의 가치를 측정하는 통제군이다.
3. C — 목적지 큐와 좌우 레버: 오너 레퍼런스에 가장 가깝고 상태 공간이 넓지만 인지부하와 제작비가 높다. 현재 구현 대상이다.
4. RealityKit 3D: 품질 상한은 높지만 이 가설 검증 범위를 넘는다. C가 통과하면 별도 spike한다.

## Acceptance Criteria

```productspec-acceptance-criteria
- id: AC-1
  criterion: The primary C-variant frame contains no flat side-view train or brake timing bar and instead shows one coherent fixed-camera 2.5D world with a front-left three-quarter train, foreground crowd, platform, and background city.
- id: AC-2
  criterion: Four destinations use the same original color, symbol, and Korean name across HUD, queue tiles, door pins, and feedback, and remain solvable from a grayscale capture.
- id: AC-3
  criterion: One-thumb left, open, and right inputs keep the visual lever position and selected door synchronized within 100 milliseconds, emit no duplicate action under multitouch or rapid repeat, and expose equivalent VoiceOver and Switch Control actions.
- id: AC-4
  criterion: Only a correctly matched door runs a continuous train-cabin to threshold to platform exchange and reverse boarding path; passenger totals exactly match visible completed crossings and no passenger intersects a closed door or train body.
- id: AC-5
  criterion: A seeded run deterministically provides five stations and ten recoverable queues, starts its 60-second scored clock after the first correct action, and permits every destination to reach three completed passengers without ads or purchases.
- id: AC-6
  criterion: Sound and haptics can be disabled independently, backgrounding pauses without automatic resume, and Reduce Motion removes parallax, camera movement, bounce, and nonessential particles while preserving all state cues.
- id: AC-7
  criterion: Free retry is always more prominent than monetization; the first three runs contain no ad CTA; any future rewarded undo grants only from a verified reward callback and no seed requires it.
- id: AC-8
  criterion: Clean-commit CI passes rule, deterministic-clock, renderer-contract, golden-screenshot, UI lever, ProductSpec, secret, and unsigned simulator build checks, while the minimum supported iPhone averages at least 55 fps with p95 frame time at most 22 milliseconds and no hitch above 100 milliseconds in a 60-second run.
- id: AC-9
  criterion: Independent target users achieve 5 of 5 two-second train recognition, at least 4 of 5 five-second explanation of matching a queue to a door with the lever, at least 8 of 10 unassisted first correct actions, median fun at least 4 of 7, median liveliness at least 5 of 7, and at least 3 of 5 voluntary third runs.
- id: AC-10
  criterion: Every runtime visual and audio asset has source, tool, prompt or brief, edit history, commercial-use basis, hash, and similarity review recorded, and no owner reference or real railway identifier is shipped.
- id: AC-11
  criterion: A TestFlight candidate passes a 30-minute minimum-device soak with no crash, leak, progression corruption, passenger-count mismatch, thermal failure, or lifecycle defect.
- id: AC-12
  criterion: Korean App Store submission does not start until signing, privacy, age rating, support URL, metadata, screenshots, review notes, analytics, rollback owner, and business validation gates are confirmed.
```

## Success Metrics

```productspec-success-metrics
- id: SM-1
  metric: unassisted_first_correct_action
  target: ">= 8 of 10 target users"
  target_status: committed
  window: moderated prototype test
- id: SM-2
  metric: lever_direction_error_rate
  target: "< 20% and no worse than automatic-alignment B without replay lift"
  target_status: committed
  window: first three runs
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
  metric: crash_free_sessions
  target: ">= 99.5%"
  target_status: committed
  window: launch-candidate TestFlight cohort
- id: SM-7
  metric: paid_acquisition_unit_economics
  target: "CPI <= observed D90 contribution LTV x 0.5 in two independent cohorts"
  target_status: committed
  window: post-launch limited Korean iOS campaign
- id: SM-8
  metric: lever_incremental_value
  target: "C beats automatic-alignment B on replay or D1 without >15% slower first win"
  target_status: committed
  window: preregistered B versus C experiment
```

## Adoption

1. 문제 인터뷰 12명과 5일 일기 8명으로 짧은 게임·광고 피로·열차 판타지 중 실제 문제를 분리한다.
2. 10명 moderated test에서 C의 최초 행동, 문 선택 오류, 군중 혼란, 멀미를 관찰한다.
3. 같은 완성도의 A/B/C playable을 방향성 100명/cell로 비교하고, 이후 baseline과 MDE로 retention 표본을 다시 산정한다.
4. no-ad TestFlight cohort에서 D1/D7과 콘텐츠 반복성을 먼저 측정한다.
5. 통과할 때만 opt-in 마지막 레버 undo를 별도 실험하고 한국 iOS 소프트런치로 CPI/LTV를 학습한다.

## Pricing

첫 후보는 무료이며 핵심 진행과 모든 재시도는 광고 없이 가능하다. 수익화는 no-ad retention 통과 후 `마지막 레버 되돌리기` 하나만 opt-in으로 검증한다. 추가 공간, 정답, 해결 가능성은 판매하지 않는다.

## Risks

- 완성도 높은 디오라마가 실제 루프보다 스토어 소재만 개선할 수 있다.
- 레버가 자동 정렬보다 이해와 첫 성공을 늦추면서 replay를 늘리지 못할 수 있다.
- 2.5D 문과 승객 레이어가 어긋나면 정적 그림처럼 보여 핵심 약속이 깨진다.
- crowd animation, atlas memory, 열, 프레임, 레벨 solvability 비용이 작은 팀의 운영 한도를 넘을 수 있다.
- 유사 장르의 광고·난이도 패턴을 답습하면 단기 수익보다 신뢰 손상이 커질 수 있다.

## Open Questions

- C의 레버가 B 자동 정렬보다 세 번째 운행과 D1을 실제로 높이는가?
- 한 번에 네 문을 보여도 색·문양 매칭을 5초 안에 설명할 수 있는가?
- 2.5D atlas가 최소 기기에서 품질과 55fps를 동시에 만족하는가?
- 한국 무료 1위에 필요한 retained daily installs, organic multiplier, CPI, 예산은 얼마인가?

## Rollout

- Gate 0 — Problem discovery: 유도 없이 반복 문제와 현재 대안을 말하는 증거가 기준을 통과한다.
- Gate A — Prototype: AC-1~AC-8, AC-10 자동·내부·오너 시각 증거 통과.
- Gate B — UX validation: AC-9와 SM-1~SM-3 통과. 실패하면 레버를 제거하거나 루프를 재설계한다.
- Gate C — Incrementality: SM-8 통과. C가 B를 이기지 못하면 C 확장을 중단한다.
- Gate D — TestFlight: AC-11, SM-4~SM-6 통과 후에만 제출 준비를 시작한다.
- Gate E — Korean soft launch: AC-12 통과 후 제한 출시한다.
- Gate F — Scale: SM-7 통과 후에만 유료 UA와 라이브옵스를 확대한다.

## Business Validation Gate

현재 판정은 **Fail / Unknown**이다. crowd-flow의 획득 proxy는 있지만 한국 iPhone retention, 레버의 증분가치, CPI/LTV, 필요한 설치량·예산 증거가 없다. 이 수치가 독립 cohort에서 재현되기 전에는 `한국 무료 1위 가능`을 주장하지 않는다.

## Launch Stop Conditions

- flat side-view 또는 제동 타이밍 bar가 C의 핵심 화면에 남아 있음.
- 2초 열차 인지 5/5, 5초 루프 이해 4/5, 무도움 첫 정답 8/10 중 하나라도 실패.
- 레버 방향 오류가 20%를 넘거나 B보다 첫 승리가 15% 이상 느린데 replay 개선이 없음.
- 승객이 문턱을 통과하지 않거나 문·차체·플랫폼을 관통함.
- 레버 표시와 선택 문이 한 프레임이라도 불일치하거나 색 없이 목적지를 구분할 수 없음.
- impossible seed, 광고 없이는 해결 불가, 무료 재시도 차단이 한 건이라도 발생.
- 2/10 이상이 멀미·군중 혼란을 보고하거나 최소 기기 성능·열 Gate를 실패.
- runtime asset provenance 또는 유사성 검토가 빠짐.
- TestFlight, 개인정보, 접근성, 서명, App Store 메타데이터 P0/P1가 하나라도 미해결.
- 두 cohort에서 D1/D7 또는 CPI/LTV Gate를 실패하거나 콘텐츠·QA 공급비가 승인 한도를 초과.

## Related Artifacts

```productspec-related-artifacts
- type: github_pr
  url: "https://github.com/keestory/kevin_game_01/pull/1"
  title: "Diorama platform-routing challenger Draft PR"
  section_id: acceptance_criteria
  item_id: AC-1
- type: other
  url: "../04-design/concepts/platform-routing-diorama-concept-v2.png"
  title: "Original platform-routing diorama concept"
  section_id: acceptance_criteria
  item_id: AC-1
- type: other
  url: "../screenshots/game-real-train-v1.png"
  title: "Owner-rejected flat side-view evidence"
  section_id: risks
- type: engineering_spec
  url: "../05-engineering/architecture.md"
  title: "Native iOS architecture"
  section_id: acceptance_criteria
  item_id: AC-8
- type: experiment
  url: "../04-design/usability-test-report.md"
  title: "External validation evidence ledger"
  section_id: success_metrics
  item_id: SM-1
```
