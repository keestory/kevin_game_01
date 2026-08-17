---
spec_format_version: "0.1"
title: "연쇄파괴: 리턴 샷 — 속성 링크와 구조 붕괴 endless prototype"
artifact_type: "hypothesis"
spec_revision: 2
author: "Product Orchestrator"
created_at: "2026-08-10T00:00:00+09:00"
updated_at: "2026-08-18T01:00:00+09:00"
linked_github_repo: "keestory/kevin_game_01"
---

## Problem

기존 열차 prototype은 한 역에서 의미 있는 입력이 한 번뿐이고 60초 뒤 기록 추격이 끝나, 반복 조작·숙련·개인 최고 기록을 만들지 못했다. 그래픽과 효과를 강화해도 코어 상호작용 부재는 해결되지 않았다.

## Hypothesis

플레이어가 한 엄지로 패들을 계속 움직여 반사각을 만들고, 색·무늬·마크 속성을 연속으로 맞혀 일시 파워를 발동하며, 직접 맞히면 감점되는 위험 벽돌은 지지점을 끊어 간접 낙하시킨다면, 단순 벽돌 제거보다 조준·위험·구조 선택의 숙련이 생기고 같은 seed의 세 번째 run 기록이 첫 run보다 상승할 것이다.

## Product Summary

`연쇄파괴: 리턴 샷`은 세로형 endless 물리 아케이드다. 공은 자동으로 왕복하고 플레이어는 패들의 접촉 위치와 이동 속도로 다음 반사각을 바꾼다. 일반·프리즘 벽돌에는 색, 무늬, 마크가 있으며 같은 속성을 연속 적중하면 LINK가 오른다. 한 속성이 5연속이면 6초간 `공명 폭주`가 발동해 속도·점수·관통력이 상승한다. 3HP 프리즘은 반복 투자 보상을 제공하고, 마이너스 벽돌은 직접 맞히지 않고 지지 구조를 무너뜨려 제거한다. run은 실수할 때까지 계속되며 점수·높이·콤보·LINK 개인 기록을 추격한다.

## Scope

```productspec-scope
in:
  - Include continuous one-thumb paddle drag and reflection controlled by contact offset plus paddle velocity.
  - Give every eligible positive brick one color, one pattern, and one mark, with all three visible without relying on color alone.
  - Track color, pattern, and mark LINK independently and activate a six-second resonance power when any one reaches five consecutive eligible direct contacts.
  - Include normal bricks, two-hit support nodes, three-hit prism bonus bricks, and indestructible negative bricks removable through support loss.
  - Apply negative score only to authoritative direct ball contact; cosmetic debris and shockwaves never cause a penalty.
  - Include deterministic support-collapse transactions, endless segment generation, score, height, combo, personal-best line, pace ghost, pause, Reduce Motion, and one-tap same-seed retry.
  - Introduce mechanics by physical height: LINK path first, prism second, negative support-drop third.
out:
  - Do not add train gameplay, station progression, rewarded continue, forced ads, friend-install rewards, pay-to-win score boosters, multiplayer, account, server, or live economy.
  - Do not use dynamic SpriteKit physics as the authoritative rules engine.
  - Do not allow random or cosmetic contacts to alter score, combo, LINK, hit points, or collapse state.
  - Do not claim App Store rank, retention, CPI, or LTV before measured evidence.
cut:
  - Cut independent pattern and mark scoring and use one redundant signature family if five-second understanding fails.
  - Cut shockwave chaining before reducing ball visibility or deterministic collision quality.
  - Cut particles, debris, and camera motion before reducing input latency or frame stability.
```

## User Experience

- 첫 5초: `끌어서 받아치세요` 한 줄과 예상 낙하지점만 보인다.
- 아래층: 접근 가능한 같은 색 경로로 첫 5-LINK와 공명 폭주를 경험한다.
- 중간층: 3회 타격 프리즘을 끝까지 노릴지, 지지점을 깨고 회수 점수만 받을지 선택한다.
- 위층: 큰 `−`, 톱니 테두리, 경고 연결선을 가진 마이너스를 피하고 아래 지지점을 노린다.
- 실패: 공이 miss line을 완전히 통과하면 0.6초 안에 결과를 보여주고 `같은 구조 다시` 한 번 탭으로 재시작한다.
- 기록: 좌측 높이 ruler에 최고 기록선, HUD에 최고 pace와 현재 차이를 표시한다.

## Core Rules

### Reflection

- 접촉 위치 `-1...1 × 42°`와 정규화한 패들 속도 `-1...1 × 20°`를 합쳐 `-62°...62°`로 제한한다.
- 패들 바깥 35%에 220pt/s 이상으로 접촉하면 1.8초 `리턴 샷`: 직접 적중 점수 ×2.
- 최소 수직 속도를 보장해 수평 무한 왕복을 막는다.

### LINK and combo

- eligible direct contact마다 색·무늬·마크 카운터를 독립 갱신한다.
- 같은 속성은 +1, 달라진 속성은 현재 벽돌 기준 1로 재시작한다.
- 속성 1개 일치 ×1.25, 2개 ×1.5, 3개 ×2.0 direct score multiplier.
- 일반 벽돌은 direct contact가 곧 파괴다. 프리즘은 첫 direct contact만 LINK를 갱신하고 이후 contact는 LINK를 보존한다.
- 지지점, 충격파, 간접 낙하는 LINK를 올리거나 끊지 않는다.
- 파괴 콤보는 1.6초 안의 직접·충격파 파괴에서 +1, 최대 ×2.5이며 구조 낙하는 한 번으로 계산한다.

### Resonance power

- 색·무늬·마크 중 하나가 정확히 5연속에 도달하면 6초 발동한다.
- 직접 점수 ×2, 공 속도 ×1.12, 일반 벽돌 관통, 프리즘·지지점 damage +1.
- 직접 적중 시 가까운 positive 이웃 최대 2개에 1 damage shockwave를 준다.
- shockwave는 LINK와 마이너스 penalty를 발생시키지 않는다.

### Prism bonus brick

- 3HP. 직접 타격 점수는 80, 140, 240이고 완파 +300.
- 같은 프리즘 반복 타격은 LINK farming이 되지 않는다.
- 지지 상실로 떨어지면 남은 HP와 무관하게 +120만 지급한다.

### Negative brick

- 직접 접촉: −250, 파괴 콤보 종료, 모든 LINK 0, 폭주 남은 시간 −2초.
- 직접 충돌로 파괴되지 않는다.
- 0.75초에 최대 한 번, 한 벽돌당 최대 두 번 penalty를 준다.
- 지지 상실: penalty 없이 낙하, `위험 제거 +120`.
- 같은 tick에는 지지 피해, collapse 계산, 남은 직접 충돌 순으로 처리한다.

## Acceptance Criteria

```productspec-acceptance-criteria
- id: AC-1
  criterion: At least four of five target users return the first ball within five seconds and explain that dragging the paddle aims the next shot upward.
- id: AC-2
  criterion: Median active-touch share is at least 60 percent, meaningful steering is 20 to 40 actions per minute, and the first thirty seconds contain no forced input gap longer than two seconds.
- id: AC-3
  criterion: Color, pattern, and mark LINK update only on eligible authoritative direct contacts; support, repeated prism, shockwave, debris, and unsupported fall cannot farm or break LINK.
- id: AC-4
  criterion: Exactly five consecutive matches in any attribute activate one six-second resonance power; cadence, duplicate contact, and simultaneous collision cannot grant it twice.
- id: AC-5
  criterion: Prism has exactly three hit points and its direct-hit, completion, powered-damage, and unsupported-fall rewards match the ProductSpec once each.
- id: AC-6
  criterion: Direct negative contact applies minus 250 and resets combo and LINK while unsupported fall gives plus 120 without penalty; a brick cannot be processed by both removal causes.
- id: AC-7
  criterion: Support collapse is deterministic by time of impact then brick ID, and every generated negative brick has an accessible support-removal path and at least two avoidable ball routes.
- id: AC-8
  criterion: The run continues beyond sixty seconds until a miss, personal-best score and height are monotonic, and one-tap same-seed retry starts within 0.8 seconds.
- id: AC-9
  criterion: Same seed and quantized input replay produce the same checksum, score, collision order, and collapse set at 30, 60, and 120 render Hz with zero tunneling or duplicate score.
- id: AC-10
  criterion: The ball, paddle, predicted landing range, signatures, prism durability, negative warning, and support links remain distinguishable without color and under Reduce Motion.
- id: AC-11
  criterion: Five users playing the same seed three times improve median run-three score or height by at least 20 percent; at least three voluntarily retry and median fun is at least four of seven.
- id: AC-12
  criterion: SwiftPM, Xcode unit and UI smoke, strict-concurrency build, secret scan, and minimum-device performance gates pass with no P0 or P1 defect.
```

## Success Metrics

```productspec-success-metrics
- id: SM-1
  metric: unassisted_first_return
  target: ">= 4 of 5 users within five seconds"
  target_status: committed
  window: moderated graybox test
- id: SM-2
  metric: voluntary_third_run
  target: ">= 3 of 5 users"
  target_status: committed
  window: same-seed moderated test
- id: SM-3
  metric: mastery_gain
  target: "median run-three score or height >= run-one x 1.20"
  target_status: committed
  window: same-seed moderated test
- id: SM-4
  metric: mechanic_understanding
  target: ">= 4 of 5 explain LINK, prism investment, and negative support-drop after first sixty seconds"
  target_status: committed
  window: moderated graybox test
- id: SM-5
  metric: day_one_retention
  target: ">= 30% provisional; recommit after baseline and MDE"
  target_status: provisional
  target_owner: "Growth and Analytics"
  window: no-ad TestFlight cohort
- id: SM-6
  metric: day_seven_retention
  target: ">= 10% provisional; recommit after baseline and MDE"
  target_status: provisional
  target_owner: "Growth and Analytics"
  window: no-ad TestFlight cohort
```

## Risks

- 세 속성과 두 특수 벽돌을 동시에 설명하면 단순성이 사라질 수 있다.
- 마이너스 우발 충돌은 단 한 번으로도 물리 공정성 신뢰를 훼손한다.
- 프리즘 반복 왕복이나 중앙 정지 패들이 단일 최적 전략이 될 수 있다.
- 속성 연속·파괴 콤보·폭주 점수가 중첩돼 한 번의 운이 전체 순위를 결정할 수 있다.
- 패들·공·파괴 구조만으로는 Breakout 계보를 벗어났다고 주장할 수 없다.

## Business Validation Gate

현재 **Fail / Unknown**이다. 이 ProductSpec은 고유 재미를 검증하는 graybox 계약이며 한국 iOS retention, CPI, LTV, 매출 상위 적합성 또는 무료 1위 가능성을 입증하지 않는다.

## Launch Stop Conditions

- 5명 중 2명 이상이 LINK 또는 마이너스 안전 제거를 설명하지 못한다.
- 마이너스 적중 중 10% 초과가 우발적이거나 20% 초과가 불공정으로 평가된다.
- Run 3의 score 또는 height 중앙값이 Run 1보다 20% 이상 개선되지 않는다.
- active-touch 중앙값 60% 미만 또는 의미 입력 분당 20회 미만이다.
- 프리즘 camping으로 3초 이상 조작 대기가 생기거나 반복 hit이 LINK를 충전한다.
- 중앙 정지 패들 또는 극단 왕복 하나가 다른 전략보다 우월하다.
- 공 관통, double score, corner jitter, invalid support graph가 한 건이라도 남는다.
- 3/5 이상이 세 번 플레이한 뒤에도 속성 경로·프리즘 투자·위험 제거 중 두 가지를 언급하지 않고 `그냥 벽돌깨기`라고만 설명한다.

## Related Artifacts

```productspec-related-artifacts
- type: github_pr
  url: "https://github.com/keestory/kevin_game_01/pull/1"
  title: "Return Shot visual MVP Draft PR"
  section_id: acceptance_criteria
  item_id: AC-12
- type: other
  url: "../01-research/endless-score-pivot-2026-08-10.md"
  title: "2026 Korea market evidence and endless score pivot"
  section_id: success_metrics
  item_id: SM-5
- type: engineering_spec
  url: "../04-design/return-shot-visual-builder-report-2026-08-17.md"
  title: "ImageGen, Vision, interaction and A/B visual QA"
  section_id: acceptance_criteria
  item_id: AC-12
```
