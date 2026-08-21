---
spec_format_version: "0.1"
title: "연쇄파괴: 리턴 샷 — 스킬 코어와 구조 붕괴 endless prototype"
artifact_type: "hypothesis"
spec_revision: 4
author: "Product Orchestrator"
created_at: "2026-08-10T00:00:00+09:00"
updated_at: "2026-08-19T01:00:00+09:00"
linked_github_repo: "keestory/kevin_game_01"
---

## Problem

기존 열차 prototype은 한 역에서 의미 있는 입력이 한 번뿐이고 60초 뒤 기록 추격이 끝나, 반복 조작·숙련·개인 최고 기록을 만들지 못했다. 그래픽과 효과를 강화해도 코어 상호작용 부재는 해결되지 않았다.

## Hypothesis

플레이어가 한 엄지로 패들을 계속 움직여 반사각을 만들고, 색·무늬·마크 속성을 연속으로 맞히며, 구조 안의 스킬 코어를 직접 노려 번개·화염·바람·관통을 run 안에서 성장시킨다면, 별도 버튼 없이도 조준·위험·빌드 선택의 숙련이 생기고 같은 seed의 세 번째 run 기록이 첫 run보다 상승할 것이다.

## Product Summary

`연쇄파괴: 리턴 샷`은 세로형 endless 물리 아케이드다. 공은 자동으로 왕복하고 플레이어는 패들의 접촉 위치와 이동 속도로 다음 반사각을 바꾼다. 일반·프리즘 벽돌에는 색, 무늬, 마크가 있으며 같은 속성을 연속 적중하면 LINK가 오른다. 한 속성이 5연속이면 6초간 `공명 폭주`가 발동한다. 구조 번호는 현재 run의 `LEVEL`이며, Level 1은 LINK와 코어, Level 2는 프리즘, Level 3은 마이너스, Level 4는 방어막을 순서대로 소개한다. 구조마다 일반 벽돌 한 개에는 번개·화염·바람·관통 코어가 순서대로 들어 있고, 그 벽돌을 직접 파괴하면 해당 공격이 즉시 발동하며 run 안에서 Lv1~3으로 성장한다. 이미 Lv3인 코어의 중복 획득은 등급을 무한히 올리지 않고 동일 대상을 15 tick 뒤 다시 치는 bounded `MAX OVERDRIVE`를 한 번 발동한다. run은 실수할 때까지 계속되며 점수·높이·콤보·LINK·스킬 빌드 개인 기록을 추격한다.

## Scope

```productspec-scope
in:
  - Include continuous one-thumb paddle drag and reflection controlled by contact offset plus paddle velocity.
  - Give every eligible positive brick one color, one pattern, and one mark, with all three visible without relying on color alone.
  - Track color, pattern, and mark LINK independently and activate a six-second resonance power when any one reaches five consecutive eligible direct contacts.
  - Include normal bricks, two-hit support nodes, three-hit prism bonus bricks, and indestructible negative bricks removable through support loss.
  - Embed exactly one deterministic attack core in a normal brick per structure; cycle lightning, flame, wind, and pierce in that order.
  - Level each attack independently from zero to three for the current run and fire the newly collected level without pausing or adding another input.
  - Expose each generated structure as the current run Level and introduce prism, negative, and armor in Levels two, three, and four respectively.
  - Make a direct duplicate of an already max-rank core fire one bounded deterministic overdrive echo without creating rank four, a new slot, or permanent account power.
  - Add a separate zero-to-two armor layer by structure while preserving every role's core hit-point contract.
  - Apply negative score only to authoritative direct ball contact; cosmetic debris and shockwaves never cause a penalty.
  - Include deterministic support-collapse transactions, endless segment generation, score, height, combo, personal-best line, pace ghost, pause, Reduce Motion, and one-tap same-seed retry.
  - Introduce mechanics by physical height: LINK path first, prism second, negative support-drop third.
out:
  - Do not add train gameplay, station progression, rewarded continue, forced ads, friend-install rewards, pay-to-win score boosters, multiplayer, account, server, or live economy.
  - Do not use dynamic SpriteKit physics as the authoritative rules engine.
  - Do not allow random or cosmetic contacts to alter score, combo, LINK, hit points, or collapse state.
  - Do not allow shockwave, unsupported fall, or another attack item to collect or recursively activate an embedded core.
  - Do not add an inventory screen, skill-choice modal, manual skill button, permanent stat upgrade, paid damage, or ad-gated armor solution.
  - Do not raise ball speed above 518 points per second before resonance, raise armor above two, or inflate core hit points by Level.
  - Do not claim App Store rank, retention, CPI, or LTV before measured evidence.
cut:
  - Cut independent pattern and mark scoring and use one redundant signature family if five-second understanding fails.
  - Cut shockwave chaining before reducing ball visibility or deterministic collision quality.
  - Cut particles, debris, and camera motion before reducing input latency or frame stability.
  - Cut attack target count and visual effects before raising armor above two or changing prism core hit points.
```

## User Experience

- 첫 5초: `끌어서 받아치세요` 한 줄과 예상 낙하지점만 보인다.
- 아래층: 접근 가능한 같은 색 경로로 첫 5-LINK와 공명 폭주를 경험한다.
- 중간층: 3회 타격 프리즘을 끝까지 노릴지, 지지점을 깨고 회수 점수만 받을지 선택한다.
- 위층: 큰 `−`, 톱니 테두리, 경고 연결선을 가진 마이너스를 피하고 아래 지지점을 노린다.
- 실패: 공이 miss line을 완전히 통과하면 0.6초 안에 결과를 보여주고 `같은 구조 다시` 한 번 탭으로 재시작한다.
- 기록: 좌측 높이 ruler에 최고 기록선, HUD에 최고 pace와 현재 차이를 표시한다.
- 스킬: 코어 벽돌은 색·무늬·마크와 겹치지 않는 모서리 배지로 구분하고, 파괴 즉시 해당 공격·레벨을 한 문장으로 알린다.

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

### Attack cores and run levels

- 구조마다 normal brick 후보를 stable ID로 정렬하고 별도 seed salt로 정확히 한 carrier를 결정한다.
- 공격 종류는 구조 순서대로 `번개 → 화염 → 바람 → 관통`을 반복한다. 같은 seed retry는 carrier와 종류가 동일하다.
- carrier를 직접 파괴했을 때만 해당 공격 레벨이 `0 → 1 → 2 → 3`으로 오른 뒤 그 레벨로 한 번 발동한다. Lv3 이후 같은 코어는 Lv3 효과만 다시 발동한다.
- shockwave, unsupported fall, attack wave로 carrier가 제거되면 코어는 획득되지 않는다.
- 공격 wave는 carrier와 negative를 대상으로 삼지 않고 LINK를 올리거나 끊지 않으며 다른 코어를 연쇄 발동하지 않는다.
- attack wave에서 여러 벽돌이 제거돼도 콤보 증가는 최대 한 번이고, 제거 점수는 기존 shockwave와 같은 벽돌당 60점이다.
- 번개: source에서 거리, brick ID 순으로 가까운 positive 1/2/3개에 1 damage.
- 화염: source 반경 72/92/112pt 안의 positive를 거리, brick ID 순으로 최대 3/5/7개에 1 damage.
- 바람: source보다 위의 positive를 y, x 거리, brick ID 순으로 2/3/4개에 1 damage.
- 관통: 1/2/3 charge를 더한다. 다음 positive direct contact에서 charge 하나를 소비하고 정상 damage 뒤 반사하지 않는다. negative contact에는 charge를 소비하지 않는다.

### Stage armor

- 구조 1~3은 armor 0, 구조 4~6은 armor 1, 구조 7 이상은 armor 2이며 그 이상 증가하지 않는다.
- armor는 모든 positive 벽돌에 적용하되 negative에는 적용하지 않는다. 기존 normal 1HP, support 2HP, prism 3HP core 계약은 유지한다.
- damage는 armor를 먼저 흡수하고 남은 damage만 core HP에 적용한다. armor-only hit은 core hit reward, 파괴, 콤보를 발생시키지 않는다.
- armor와 core HP는 별도 모양으로 표시하며 색만으로 구분하지 않는다.

### Visible Level and difficulty

- `LEVEL = segment + 1`이며 positive 구조가 모두 제거될 때만 다음 Level로 진행한다. 타이머로 강제 전환하지 않는다.
- Level 1은 prism 0·negative 0, Level 2는 prism 1·negative 0, Level 3은 prism 1·negative 1, Level 4 이상은 prism 2·negative 2다. 고정된 후보 위치의 앞 N개만 사용해 seed와 support graph를 보존한다.
- 진입 공 속도는 Level 1~5에서 370/388/407/425/444pt/s, Level 6부터 Level당 15pt/s 증가하며 518pt/s에서 멈춘다. 시간에 따른 숨은 속도 증가는 사용하지 않는다.
- armor는 Level 1~3에서 0, Level 4~6에서 1, Level 7 이상에서 2이며 그 이상 증가하지 않는다.
- Level 배너는 `LEVEL N · ARMOR +M`을 0.7초 이내 비차단 표시한다. 배너·효과 때문에 simulation tick이나 패들 입력을 멈추지 않는다.

### MAX OVERDRIVE

- 발동 전부터 해당 공격이 Lv3이고 carrier를 공으로 직접 파괴한 경우에만 발동한다. 공격 등급은 계속 Lv3이다.
- 번개·화염·바람은 기존 Lv3 stable target IDs에 primary 1 damage를 적용한 뒤 정확히 15 authoritative tick 후 생존한 동일 IDs에 1 damage echo를 적용한다. 사라진 대상을 다른 벽돌로 대체하지 않는다.
- 관통은 primary +3 charge, 15 tick 뒤 echo +3 charge를 주되 총 보유량은 6으로 제한한다.
- pending echo는 trigger tick, segment, carrier ID, kind, activation sequence, 정렬 target IDs를 권위 상태와 checksum에 포함한다.
- primary와 echo 전체가 combo를 최대 한 번만 올리고, LINK·negative·다른 carrier·다른 item을 공격하거나 발동하지 않는다.
- pending echo가 있으면 다음 Level 생성만 최대 15 tick 유예한다. 공과 패들 입력은 계속 진행한다.
- MAX 연출은 공격별 형태를 유지하고 공 아래 z-order, 전체 transient node 64개, 공격 root 8개, flash alpha 0.12 이하를 지킨다. Reduce Motion에서는 camera motion 없이 짧은 outline pulse 두 번으로 대체한다.

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
- id: AC-13
  criterion: Every structure has exactly one deterministic normal-brick carrier and cycles lightning, flame, wind, and pierce without changing the existing signature, role, or support random stream.
- id: AC-14
  criterion: Only direct carrier removal levels and activates an attack; unsupported fall, resonance, or another attack wave cannot collect a core, target a negative brick, change LINK, or recursively activate an item.
- id: AC-15
  criterion: Lightning, flame, and wind use their bounded level-one through level-three target counts with stable tie-breaking, while pierce consumes exactly one charge only on a positive direct contact.
- id: AC-16
  criterion: Structure armor follows zero, one, and two-layer boundaries, absorbs damage before core hit points, never exceeds two, and leaves prism core durability at exactly three.
- id: AC-17
  criterion: On a 375 by 667 point display, four skill levels, active feedback, armor, ball path, LINK, negative warning, and primary controls remain distinguishable without clipping or relying on color alone.
- id: AC-18
  criterion: Level equals segment plus one, uses the committed role-introduction counts, entry-speed curve, and armor bands, never advances on a timer, and never raises pre-resonance speed above 518 points per second.
- id: AC-19
  criterion: A duplicate max-rank direct core schedules exactly one overdrive echo at current tick plus fifteen against the original stable target IDs, never retargets or recursively collects, and primary plus echo awards at most one combo.
- id: AC-20
  criterion: Level and overdrive presentation never pause authoritative ticks or input, stays below the ball, obeys transient and flash budgets, and has a Reduce Motion substitute on 375 by 667 and 402 by 874 displays.
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
- id: SM-7
  metric: skill_core_understanding
  target: ">= 4 of 5 users explain that directly breaking the marked brick levels and fires its attack"
  target_status: committed
  window: moderated same-seed test
- id: SM-8
  metric: skill_core_replay_lift
  target: "skill-core build improves voluntary third run without reducing active-touch share below 60%"
  target_status: provisional
  target_owner: "Product and UX Research"
  window: baseline versus skill-core prototype
- id: SM-9
  metric: progression_understanding
  target: ">= 4 of 5 explain Level role introduction and same-core L1 to L3 growth; first same-kind L2 within 120 seconds"
  target_status: committed
  window: moderated same-seed test
```

## Risks

- 세 속성과 두 특수 벽돌을 동시에 설명하면 단순성이 사라질 수 있다.
- 마이너스 우발 충돌은 단 한 번으로도 물리 공정성 신뢰를 훼손한다.
- 프리즘 반복 왕복이나 중앙 정지 패들이 단일 최적 전략이 될 수 있다.
- 속성 연속·파괴 콤보·폭주 점수가 중첩돼 한 번의 운이 전체 순위를 결정할 수 있다.
- 패들·공·파괴 구조만으로는 Breakout 계보를 벗어났다고 주장할 수 없다.
- 네 공격이 기존 공명 shockwave·관통과 겹치거나 `PunBall`의 축소판처럼 보일 수 있다.
- armor가 조준 숙련보다 반복 타격을 강제하면 즉시 스펀지 난이도가 된다.
- 공격 효과가 carrier·negative·지지선을 가리거나 RNG가 PB 공정성을 훼손할 수 있다.

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
- 5명 중 2명 이상이 carrier를 LINK 속성으로 오인하거나 직접 파괴해야 획득한다는 규칙을 설명하지 못한다.
- 일반 벽돌이 armor 때문에 세 번을 초과해 맞아야 하거나 3초 이상 같은 벽돌 반복 타격을 요구한다.
- attack wave가 negative를 때리거나 LINK·다른 core를 한 번이라도 발동한다.
- 스킬 도입 후 active-touch가 60% 미만이거나 자발적 3회차가 baseline보다 개선되지 않는다.
- 10,000 seed 중 코어 미획득 softlock, 접근 불가 지지 경로, 무광고 불가능 구조가 한 건이라도 발생한다.
- MAX OVERDRIVE 한 번이 구조의 50%를 초과해 자동 제거하거나 run 점수의 25%를 초과한다.
- 5명 중 2명 이상이 Level 3/MAX 차이를 오인하거나 MAX 중복을 헛아이템으로 평가한다.

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
- type: engineering_spec
  url: "../04-design/skill-core-visual-audit-2026-08-18.md"
  title: "Skill core visual and accessibility audit"
  section_id: acceptance_criteria
  item_id: AC-17
```
