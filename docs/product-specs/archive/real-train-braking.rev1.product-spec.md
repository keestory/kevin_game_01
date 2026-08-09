---
spec_format_version: "0.1"
title: "정위치! 만원열차 — 한국 iPhone vertical slice"
artifact_type: "hypothesis"
spec_revision: 1
author: "Product Orchestrator"
created_at: "2026-08-09T12:30:00Z"
updated_at: "2026-08-09T12:30:00Z"
linked_github_repo: "keestory/kevin_game_01"
---

## Problem

한국 iPhone 사용자는 통근·통학·대기 중 1분 안에 시작하고 끝낼 수 있는 한 손 게임을 원할 수 있지만, 현재 경쟁 캐주얼 게임의 방해성 광고와 불공정한 난이도에 불만을 제기한다. 이 문제의 빈도·강도와 열차 소재 선호는 아직 실제 목표 사용자 인터뷰로 검증되지 않았다.

## Hypothesis

첫 프레임부터 실제 지하철 한 량이 달리고, 사용자가 정차선에 맞춰 한 번 탭한 뒤 세 쌍의 문으로 사람 승객이 직접 타고 내리면, 추상 격자보다 목표를 빨리 이해하고 60초 운행을 자발적으로 반복할 것이다. 무료 재시도를 기본으로 하고 강제 광고와 친구 설치 보상을 제외하면 초기 신뢰를 해치지 않으면서 선택형 Continue를 나중에 검증할 수 있다.

## Product Summary

`정위치! 만원열차`는 5개 역을 12초씩 달리는 세로형 원탭 제동 게임이다. 정차 타이밍이 하차 인원과 점수를 결정하며, 실제 객차·문·플랫폼·사람 승객·시청각·햅틱 피드백으로 입력과 결과를 연결한다. 현재 산출물은 출시 후보가 아니라 시장·이해·재플레이 가설을 검증하는 vertical slice다.

## Scope

```productspec-scope
in:
  - Include a Korean-language iPhone portrait vertical slice with one actual side-view subway car.
  - Include five deterministic station plans in a nominal 60-second run.
  - Include one-tap braking, three sliding door pairs, and human-shaped passengers visibly crossing the door threshold.
  - Include first-run coaching that remains until the first brake result and does not consume time before braking becomes available.
  - Include score, exited-passenger target, free retry, pause/background safety, sound, haptics, and Reduce Motion support.
  - Include a ProductSpec Product Harness with durable acceptance criteria, success metrics, evidence links, Agent Run receipts, Decision Trace, and CI validation.
  - Include a TestFlight validation plan and a conditional Korean App Store launch checklist.
out:
  - Do not claim or guarantee Korean App Store rank 1 before measured acquisition, retention, and unit-economics evidence exists.
  - Do not ship forced interstitial ads, pay-to-pass difficulty, or rewards for friend install or signup.
  - Do not integrate a real rewarded-ad SDK until three clean runs and free retry are validated.
  - Do not copy railway trademarks, liveries, maps, characters, music, or announcements.
  - Do not build real-time multiplayer, a large collection meta, season pass, or backend account system in this revision.
cut:
  - Cut rewarded Continue from the launch candidate if reward delivery, policy, or user-trust tests are incomplete.
  - Cut daily seed sharing if deep-link abuse prevention and attribution are not ready.
  - Cut nonessential particles and background parallax before reducing input clarity or frame stability.
```

## User Experience

- 0–2초: 텍스트 없이도 차체·창·문·바퀴·선로·플랫폼으로 “열차 게임”임을 인지한다.
- 첫 입력 전: `노란 구간에서 ‘지금 제동’을 누르세요` 안내가 유지되고, 제동 가능 구간 전에는 60초가 줄지 않는다.
- 제동: 버튼이 `역 접근 중`에서 `지금 제동`으로 바뀌며 정차선은 색·흰 선·텍스트로 중복 표시된다.
- 결과: 열차가 감속하고 문이 열린 뒤 사람 승객이 문턱을 통과하며 하차 인원·등급·사운드·햅틱이 함께 나온다.
- 실패: 이유를 설명하고 `같은 운행 다시`를 광고 없이 제공한다.

설계 근거는 `docs/04-design/design-system.md`, 콘셉트는 `docs/04-design/concepts/real-train-vertical-slice-concept-v1.png`, 현재 화면은 `docs/screenshots/home-real-train-v1.png`와 `docs/screenshots/game-real-train-v1.png`다.

## Customer Truth

- 2026-08-09 Apple 한국 무료 Games 웹 차트에서 Bus Traffic Fever가 #11이었고, 같은 날 RSS는 #13이었다. 동적 순위는 획득 훅의 사례일 뿐 본 제품 수요 증거가 아니다.
- 차량·열차 게임의 Google Play 1,000만+ 표시는 글로벌 Android 누적 도달 사례이며 한국 iPhone 적합성을 입증하지 않는다.
- 한국 최고매출 Games Top 25에는 직접 열차·교통 퍼즐이 관측되지 않았다.
- 프로젝트 오너는 기존 추상 5×7 격자에 대해 재미·그래픽·효과가 부족하고, 하차 게임이라면 실제 열차가 보여야 한다고 판단했다.
- 목표 사용자 인터뷰, 무보조 사용성 결과, D1/D7, CPI, eCPM, LTV는 아직 없다.

## Solution Alternatives

1. 5×7 승객 매치 격자: 구현은 쉬우나 열차와 행동의 인과가 약해 폐기했다.
2. 선로 전환 전략: 열차 판타지는 강하지만 한 손 60초 목표보다 학습 부담이 크다.
3. 정차선 제동 원탭: 실제 열차·승하차를 가장 짧은 입력–결과 고리로 보여 현재 검증안으로 선택했다.
4. 대형 방치형 RPG/머지 메타: 차트 사례는 있으나 소규모 vertical slice 범위를 넘어 제외했다.

## Acceptance Criteria

```productspec-acceptance-criteria
- id: AC-1
  criterion: The first gameplay frame renders an unmistakable side-view train with body, windows, three door pairs, wheels, rails, platform, and human-shaped passengers without third-party IP.
- id: AC-2
  criterion: On a migrated or new profile, first-run coaching remains visible until the first brake result, the countdown does not decrease before braking becomes available, and the brake CTA changes from approach to action wording.
- id: AC-3
  criterion: A seeded run resolves the same five station plans, timing grades, exited counts, and scores deterministically, with the initial target set to at least 22 of 32 passengers.
- id: AC-4
  criterion: For every non-missed stop, all three door pairs visibly open and human-shaped passengers animate across a door threshold before the doors close.
- id: AC-5
  criterion: Sound and haptics can be disabled independently, backgrounding pauses without automatic resume, and Reduce Motion removes nonessential shake, particles, and parallax without hiding game state.
- id: AC-6
  criterion: Free retry remains available without ads or friend actions; Release hides rewarded Continue until a real SDK is integrated and rewards are granted only by a verified reward callback.
- id: AC-7
  criterion: Swift rule tests, iOS unit tests, UI smoke tests, ProductSpec validation, secret scanning, and an unsigned simulator build all pass for the pinned Product Spec revision.
- id: AC-8
  criterion: Separate unexposed panels complete the 2-second train-recognition test and 5-second goal-explanation test, followed by a five-person three-run playtest, with no P0 or unresolved P1 usability defect.
- id: AC-9
  criterion: A TestFlight release passes a 30-minute soak on the minimum supported iPhone profile with no crash, no gameplay hitch over 100 milliseconds, no leak, and no progression or reward corruption.
- id: AC-10
  criterion: Korean App Store submission does not start until App Store Connect access, signing, privacy answers, age rating, support URL, screenshots, metadata, review notes, and a release rollback owner are confirmed.
```

## Success Metrics

```productspec-success-metrics
- id: SM-1
  metric: two_second_train_recognition
  target: "5 of 5 target users"
  target_status: committed
  window: pre-TestFlight moderated test
- id: SM-2
  metric: five_second_goal_explanation
  target: ">= 4 of 5 target users"
  target_status: committed
  window: pre-TestFlight moderated test
- id: SM-3
  metric: voluntary_second_run
  target: ">= 4 of 5 target users"
  target_status: committed
  window: first prototype session
- id: SM-4
  metric: fun_score_median
  target: ">= 4 of 7"
  target_status: committed
  window: after three runs
- id: SM-5
  metric: third_run_completion_rate
  target: ">= 60%"
  target_status: provisional
  target_owner: "Product Orchestrator"
  window: first 30 external TestFlight users
- id: SM-6
  metric: day_one_retention
  target: "set after 30-user baseline; do not scale UA before target is committed"
  target_status: provisional
  target_owner: "Growth and Analytics"
  window: first TestFlight cohort
- id: SM-7
  metric: crash_free_sessions
  target: ">= 99.5%"
  target_status: committed
  window: launch-candidate TestFlight cohort
- id: SM-8
  metric: paid_acquisition_unit_economics
  target: "D7 contribution LTV >= CPI before paid scale"
  target_status: committed
  window: post-launch limited campaign
```

## Adoption

1. 문제 인터뷰 12명과 5일 일기 8명으로 문제·현재 대안·발생 맥락을 먼저 확인한다.
2. 서로 다른 신규 패널로 2초 열차 인지 5명, 5초 목표 설명 5명, 3회 실플레이 5명을 검증한다.
3. 30명 TestFlight 방향성 cohort로 3회차, 성능, 오류, 멀미, 초기 유지 신호를 확인한다.
4. 방향성이 확인되면 효과를 검출할 표본을 다시 산정해 정지형 대 이동형, 무광고 대 선택형 Continue 실험을 사전 등록한다.
5. 한국 App Store에 소프트런치하되 유료 UA는 소액 학습 예산으로 제한한다.
6. D1/D7과 CPI/LTV가 정해진 Gate를 넘을 때만 소재·이벤트·수집 메타를 확장한다.

## Pricing

첫 출시 후보는 무료다. 첫 3회 플레이, 모든 재시도, 핵심 진행은 광고 없이 제공한다. 보상형 광고는 사용자 검증과 실제 SDK 정책 감사 후 `마지막 제동 1회 되돌리기`와 `추가 역 1회`를 별도 A/B하는 미검증 가설이며, IAP 가격은 유지·전환 데이터 전에는 정하지 않는다.

## Risks

- 실제 열차 비주얼이 획득에는 유리해도 제동 한 가지 행동만으로 3회 이상 재미가 지속되지 않을 수 있다.
- 이동 배경과 흔들림이 멀미·오탭을 만들 수 있다.
- 플랫폼 승객, 문, 차내 승객의 레이어가 겹치면 “실제 승하차” 약속이 깨진다.
- 글로벌 Android 다운로드 사례를 한국 iPhone 수요로 오해할 수 있다.
- 차트 1위는 제품성 외에도 IP, UA, 피처링, 라이브옵스 영향을 받으므로 현재 증거로 예측할 수 없다.

## Open Questions

- 목표 사용자가 실제로 느끼는 문제는 “짧은 게임 부족”인가, “광고 피로”인가, “열차 판타지 부족”인가?
- 정차 타이밍만으로 세 번째 운행까지 재미가 유지되는가?
- 실제 질감의 사운드가 합성음보다 반복 의향을 높이는가?
- 실패 Continue는 마지막 제동 되돌리기와 추가 역 중 무엇이 더 공정하게 느껴지는가?
- 무료 1위에 필요한 한국 일일 다운로드와 유기/유료 비중은 얼마인가?

## Rollout

- Gate 0 — Problem discovery: 12명 중 최소 6명이 유도 없이 반복 문제와 현재 대안을 설명하고, 8명 중 최소 4명이 5일 중 3일 이상 실제 맥락을 기록한다.
- Gate A — Prototype: AC-1~AC-7 자동·내부 증거 통과.
- Gate B — UX validation: AC-8과 SM-1~SM-4 통과. 실패하면 출시 기능 추가를 중단하고 루프를 재설계한다.
- Gate C — TestFlight: AC-9, SM-5, SM-7 통과. 실패하면 App Store 제출을 중단한다.
- Gate D — Korean soft launch: AC-10 통과 후 제한 출시. 개인정보·광고·결제 미완료 시 기능을 제거하거나 제출을 중단한다.
- Gate E — Scale: SM-6 목표를 실측으로 확정하고 SM-8 통과 후에만 유료 UA와 라이브옵스를 확대한다.

## Business Validation Gate

현재 판정은 **Fail**이다. 아래 증거가 모두 연결되기 전에는 “사업 검증 완료” 또는 “1위 가능”을 주장하지 않는다.

1. Gate 0 문제 발견 통과.
2. 이동 열차가 정지형보다 첫 행동 이해·3회차 재플레이를 개선하고 멀미·오탭 가드레일을 통과.
3. 광고 없는 cohort에서 D1/D7 baseline과 목표를 Decision Trace로 확정.
4. 선택형 광고가 사전 등록한 유지율 비열등성 한도 안에서 실제 contribution을 생성.
5. 실제 한국 iOS CPI가 관측 D90 contribution LTV의 50% 이하로 독립 cohort 두 번에서 재현.
6. 콘텐츠·QA·지원 운영비가 프로젝트 오너의 사전 승인 한도 이내.
7. Analytics, 개인정보, 접근성, 서명·Archive, P0/P1 Release Gate 통과.

## Launch Stop Conditions

- 증거가 없는 P0 Acceptance Criterion이 하나라도 있음.
- 2초 열차 인지 5/5, 5초 목표 이해 4/5, 재미 중앙값 4/7, 자발적 재시도 4/5 중 하나라도 실패.
- 이동형이 정지형보다 오탭을 상대 20% 이상 높이거나 10명 중 2명 이상이 멀미·시각 혼란을 보고.
- 문을 통과하는 승객이 보이지 않거나 차체를 관통.
- 광고 거절·로드 실패가 무료 재시도를 막거나 첫 세 운행에 광고 CTA가 노출.
- 실제 기기 성능, 개인정보, 광고 SDK, 접근성, 서명, App Store 메타데이터 P0/P1가 하나라도 미해결.
- 스토어 전환은 상승하지만 D1이 하락하거나, CPI/LTV Gate가 두 cohort에서 실패.

## Related Artifacts

```productspec-related-artifacts
- type: github_pr
  url: "https://github.com/keestory/kevin_game_01/pull/1"
  title: "Initial real-train vertical slice Draft PR"
  section_id: acceptance_criteria
  item_id: AC-1
- type: other
  url: "../04-design/concepts/real-train-vertical-slice-concept-v1.png"
  title: "Original real-train visual concept"
  section_id: acceptance_criteria
  item_id: AC-1
- type: engineering_spec
  url: "../05-engineering/architecture.md"
  title: "Native iOS architecture"
  section_id: acceptance_criteria
  item_id: AC-5
- type: experiment
  url: "../04-design/usability-test-report.md"
  title: "Usability evidence and open external-test cells"
  section_id: success_metrics
  item_id: SM-1
- type: analytics_snapshot
  url: "../08-growth/weekly-metrics.md"
  title: "Post-launch metric ledger"
  section_id: success_metrics
  item_id: SM-6
```
