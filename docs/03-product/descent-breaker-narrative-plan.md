# Descent Breaker Narrative Plan

- Version: Superseded proposal v0.2
- Date: 2026-08-21 KST
- Stage: 4. Solution Definition
- Status: Superseded by the ranking-first continuous-run direction in `descent-breaker-ranked-endless-concept.md`. Retained only as decision history.
- Authority: This document does not change `descent-breaker.product-spec.md`, authoritative simulation, score, spawn, Choice Arena, BREAK FLOW, retry, or analytics contracts.

## 1. Goal and Gate

### Goal

Give the current 60-second action loop a memorable reason to exist without delaying the first input or adding a separate meta game.

### Hypothesis

A very thin story layer can make ship choice, element pickups, BREAK FLOW, risk choice, failure, and same-seed retry feel like one coherent mission.

### Gate

The proposal may advance to a copy-and-art-only prototype only when all conditions below are true.

1. At least 4 of 5 first-time users can explain within 3 seconds that they move a ship and destroy falling threats before the danger line.
2. Unassisted first movement remains at or below 2 seconds and first destruction at or below 3 seconds.
3. Story-on does not underperform story-off on voluntary third-run completion in the directional usability test.
4. Story changes no authoritative state, timer, score, spawn, checksum, Choice, BREAK FLOW, or retry behavior.
5. The active BREAK FLOW research build remains story-off.

## 2. Narrative North Star

### Logline

> 무너진 상공도시의 잔해가 마지막 지상 리액터로 쏟아지는 60초. 플레이어는 파쇄 기체와 동기화해 위협을 부수고, 그 안의 원소 코어를 회수하며 생존과 최고 기록 사이의 항로를 선택한다.

### Theme

> 우리를 파괴하러 떨어지는 것이, 다시 우리를 살릴 에너지가 된다.

The story is about mastery and prioritization under pressure, not collecting power for its own sake. The player gets better at solving the same crisis; the game does not pretend that a permanent stat increase caused that mastery.

### ASO / Creative sentence

> 쏟아지는 도시 잔해를 한 손으로 부수고, 같은 낙하 궤적의 최고 기록을 돌파하라.

This is a proposal, not a validated acquisition claim. Do not use `한국 1위`, `최고`, or `중독성 보장` in marketing copy.

## 3. World Rules Mapped to Existing Mechanics

| Existing mechanic | Narrative meaning |
|---|---|
| 60-second run | Orbital sensors can predict one falling-debris window for exactly 60 seconds. |
| Reactor 3 HP | The last ground reactor maintains three shield rings; each danger-line breach disables one ring. |
| Five lanes and drag | Automated interception is possible only in five safe corridors. The pilot moves synchronization between them. |
| Auto fire | The chosen demolition craft fires according to its own fixed interception rhythm. |
| Normal object | Cargo module from the collapsed sky city. |
| Armored object | Reinforced structural frame. |
| Spike object | Unstable attitude-control wreckage. |
| Drone object | Maintenance drone that lost central control. |
| Core object | Energy capsule from the former sky-city grid. |
| Fire, electric, pierce, wind, explosion L0-L3 | Unstable elemental cores synchronize only for the current falling window and discharge at its end. |
| BREAK FLOW | Direct eight-chain destruction creates temporary pilot-craft synchronization. Automatic elemental waves do not prove pilot mastery. |
| Choice Arena at 30 seconds | The pilot selects a stable route or redline protocol. Neither option is morally superior. |
| Seed | A recorded falling-orbit `TRACE`. |
| Same-seed retry | A tactical replay of the same stored TRACE, not time travel. |
| Score / PB | Destruction efficiency and the best defense record for that TRACE. |

There is no alien invasion, villain, enemy army, player hit point, or hidden war in the MVP story. The antagonist is the continuing disaster called `the Descent`.

## 4. Player Role and Character Layer

The player is an unnamed remote `Descent Breaker` pilot. A fixed human hero, portrait, dialogue screen, or voice actor is not required. Character comes from the onboard AI associated with the selected craft.

| Craft | AI | Personality | Preflight line | Existing weapon meaning |
|---|---|---|---|---|
| Swift S-1 | PIN / 핀 | Precise, calm, very brief | `빈틈 하나면 충분해.` | Fast single pulse |
| Hammer H-2 | ANVIL / 모루 | Relaxed but decisive | `단단할수록, 확실하게.` | Slower damage-2 lance |
| Trident T-3 | ARGO / 아르고 | Wide awareness, distributes risk | `세 갈래도 한눈에 본다.` | Three-lane salvo |

MVP exposure is one preflight sentence only. Portraits, live dialogue, voice-over, relationship systems, and AI conversations are out of scope.

## 5. Content Hierarchy and Play Length

`60 seconds` is one TRACE, not one chapter.

| Layer | Structure | Role |
|---|---|---|
| Run / TRACE | One deterministic seed, exactly 60 seconds | Immediate score, PB, chain, and retry challenge |
| Sector | Three TRACE routes: A, B, and C | One required story route plus two optional mastery routes |
| Chapter | Four Sectors, twelve TRACE routes | One narrative conflict and visual identity |
| Campaign | Five Chapters | Twenty required TRACE routes and forty optional mastery TRACE routes |

### Completion ranges

- Critical story route: `5 chapters × 4 required TRACE = 20 runs`, or 20 minutes of perfect combat time.
- With 8-12 second transitions and an internal assumption of 1.25-1.5 attempts per required TRACE, the first story clear is approximately 28-36 minutes.
- Full mastery route: `5 chapters × 4 sectors × 3 TRACE = 60 runs`, or 60 minutes of perfect combat time.
- With an internal assumption of 1.5-2.5 attempts per TRACE, full TRACE completion is approximately 90-150 minutes of combat.

These are internal planning scenarios, not observed retention or completion benchmarks. Optional TRACE routes must prove that different seeds create meaningful mastery before all forty are produced.

Chapter 5 ends the defense of the first night, not the game. A future `ENDLESS SHIFT` may supply an unlimited catalog of separate 60-second TRACE runs. It is not one infinitely extending run: every 60 seconds produces a result, then the player chooses same-TRACE retry or a new TRACE. Extra time, HP carry-over, and permanent run power remain out of scope.

### First validation slice

Build and test only Chapter 1's four required TRACE routes first. Do not author the other sixteen required routes or forty optional routes until:

1. At least 4 of 5 users complete all four Chapter 1 TRACE routes.
2. At least 3 of 5 voluntarily start a PB retry, another TRACE, or the next-session option within 60 active seconds.
3. At least 3 of 5 improve their score by 20% or more between the first and third attempt on the same TRACE and craft.
4. Fewer than 2 of 5 describe the TRACE routes as `the same stage with a different name`.

Chapter map, progression persistence, Daily TRACE, and ENDLESS SHIFT require separate ProductSpec approval. They are not authorized by this narrative document.

## 6. Five-Chapter Story Arc

Each chapter is a proposed title, background, copy, and approved-seed family containing four Sectors. It does not authorize a new enemy, boss, currency, permanent upgrade, goal, or simulation rule. Only Chapter 1's four required TRACE routes belong in the first story prototype.

| Chapter | Conflict and focus | Start | Success | Failure |
|---|---|---|---|---|
| 1. 첫 번째 비 | First recorded Descent; learn survival and core recovery | `TRACE 01 · 하늘이 무너진다. 첫 60초를 지켜라.` | `SECTOR SECURED · 첫 비를 막았다.` | `REACTOR OFFLINE · 같은 궤적을 다시 읽는다.` |
| 2. 강철의 무게 | Reinforced wreckage makes prioritization visible | `TRACE 02 · 강화 잔해 접근. 붉은 선을 넘기지 마라.` | `강철비 종료 · 산업구 냉각선 확보.` | `강화 잔해가 방어선을 돌파했다. TRACE 재연결.` |
| 3. 남겨진 불빛 | Threat-versus-core collection tension | `TRACE 03 · 잔해 속 원소 코어를 회수하라.` | `회수 코어가 도시의 불을 되살렸다.` | `방어선 단절 · 회수 경로를 다시 계산한다.` |
| 4. 두 개의 항로 | Stable route versus redline choice | `TRACE 04 · 30초 뒤 비행 프로토콜이 갈린다.` | `안정 항로 완료.` / `레드라인 구간 돌파.` | `항로 붕괴 · 동일 TRACE 재진입 가능.` |
| 5. 마지막 낙하 | Final density window and BREAK FLOW mastery | `TRACE 05 · 마지막 낙하창. 60초를 지켜라.` | `DESCENT CLEARED · 도시는 오늘 밤을 넘겼다.` | `리액터 오프라인 · 마지막 TRACE를 다시 연다.` |

Any change to chapter spawn distribution or difficulty must return to ProductSpec approval. A chapter title alone does not authorize it.

## 7. One-Run Narrative Rhythm

| Time | Narrative job | Presentation rule |
|---|---|---|
| Preflight | Express the chosen craft's firing personality | One AI sentence; no modal tutorial |
| 0-3s | Establish TRACE and immediate threat | One non-blocking line; input has priority |
| 3-8s | Give the player control over the falling sky | Destruction feedback, no dialogue |
| 8-12s | Teach that danger can become energy | First core pickup line only |
| 12-20s | Increase the felt weight of the fall | Existing armor and hit feedback |
| 20-30s | Show pressure and mastery together | Danger saves and direct chain feedback |
| 30s | Make the run's sole explicit story choice | Existing Choice Arena; neutral wording |
| 30-45s | Let the chosen protocol and elemental growth speak | No new dialogue; `파쇄 동기화` may support BREAK FLOW |
| 45-55s | Peak crisis | Effects and object density carry the story |
| 55-60s | Close the defense window | Existing countdown only |
| Result | Convert outcome into replay motivation | One outcome line plus `같은 TRACE 다시` |

## 8. MVP Story Surface

The first prototype exposes story at five bounded points only.

1. Home premise: `하늘이 무너진다.` / `60초 동안 마지막 리액터를 지켜라.`
2. Ship selection: one onboard-AI line.
3. Run start: `TRACE 01 · 첫 번째 비`.
4. Choice Arena: retain existing stable-route and redline decision; do not moralize either choice.
5. Result: success or failure line plus `같은 TRACE 다시`.

First core pickup may show once: `이번 TRACE 동안 동기화`. Do not imply permanent growth or currency.

### Explicitly out of scope

- Cutscenes, dialogue panels, NPC portraits, live chatter, or voice-over
- Chapter map, quest log, collection book, city-rebuilding currency, or permanent power
- New boss, enemy bullets, combat objectives, or new elemental types
- Story state in the authoritative run model
- Story-specific analytics in the first prototype
- New art assets before provenance and commercial-use rights are recorded

## 9. Presentation and Technical Boundary

Story is a presentation-only content catalog. It must not enter `DescentModels`, `DescentRules`, the fixed 120 Hz simulation, checksum, score, spawn order, Choice outcome, BREAK FLOW activation, or retry seed.

If implemented after approval, the minimum proposed boundary is:

- Static typed story IDs and localized content catalog
- A presentation policy with `standard` and `suppressedForResearch`
- No read-state persistence in v1
- No run-start or abandonment event caused by opening a briefing
- Story-on and story-off must produce identical 7,200-tick checksum, score, and ordered domain events for the same input

The current BREAK FLOW participant study and `-descentResearch` launch path remain story-off. Mixing the two changes invalidates the single-variable research design.

## 10. Accessibility and Localization

- Gameplay copy must remain readable at 375x667 and larger portrait sizes without hiding the craft, danger line, objects, drops, or hit point state.
- VoiceOver announces the mission summary once, not every flavor line.
- Dynamic Type may reflow preflight and result text; live-field copy must use a bounded layout.
- Color is never the only distinction for core type, danger, or Choice.
- Korean is the first authored language; all runtime copy must move through String Catalog before release.
- `TRACE` needs a one-time plain-language explanation: `센서가 저장한 낙하 궤적`.

## 11. Story A/B Validation

Do not run this test until the current BREAK FLOW research is complete and its participant assignment/reporting defect is fixed.

### Design

- New Korean iPhone casual-action users: 10 total
- Neutral: 5; micro-story: 5
- No crossover exposure
- Same rules version, seed, ship, difficulty, Choice, and gameplay effects
- Only copy, naming, and approved visual identity differ

### Primary directional metrics

1. Story comprehension: at least 4 of 5 story users explain threat, action, and defense objective correctly.
2. Voluntary third-run completion within 60 active seconds after two required runs: at least 3 of 5, and not worse than neutral.
3. At least 4 of 5 connect debris, cores, BREAK FLOW, and TRACE names to their real gameplay functions.

### Stop conditions

- First movement exceeds 2 seconds or first destruction exceeds 3 seconds.
- At least 2 of 5 users say they were delayed by reading or cannot explain the objective within 5 seconds.
- Any story overlay hides the player, danger line, object, drop, or hit-point state.
- At least 2 of 5 mistake cores, onboard AI, or PB for permanent power, currency, or auto-play.
- At least 2 of 5 understand same-TRACE retry as literal time travel.
- Story wording pushes Choice Arena outside the pre-registered 20-80% branch guardrail.
- Story-on reduces voluntary replay with no clear comprehension or emotional benefit.

The test is directional usability evidence only. It cannot establish D1, D7, revenue, or Korean App Store rank.

## 12. Red-Team Notes

1. `Last city plus AI companion` is familiar science-fiction material. Differentiation must stay centered on discarded human infrastructure becoming both threat and survival energy.
2. `첫 번째 비` may sound like a weather game; validate it in the 3-second comprehension test.
3. More dialogue would compete with object, drop, danger, and chain recognition. The live field therefore has no character conversation.
4. Redline must not be framed as brave or correct, and steady must not be framed as cowardly.
5. A story-heavy solution creates localization, art, accessibility, QA, and content-production cost without current retention evidence.

## 13. Agent Synthesis and Decision

### Participating roles

- Product Orchestrator: integrated scope, evidence, conflicts, and Gate
- Game Narrative & Worldbuilding: premise, world rules, characters, chapters, run beats, replay meaning
- Strategy / Market / Growth / Marketing: 3-second understanding, creative promise, replay hypothesis, Story A/B and Stop criteria
- Product Planning / Solution Architecture / Engineering / QA / Security & Privacy: presentation-only boundary, research isolation, localization, accessibility, deterministic regression

### Decision

- `Conditional Go`: preserve this proposal as the narrative direction.
- `Revise`: do not implement it in the active research build.
- Next approval unit: four required TRACE routes for Chapter 1 as a micro-story prototype, followed by visual and interaction QA, then a separate Story A/B.

### Unknowns

- Whether the premise improves voluntary replay or emotional recall
- Whether TRACE is understandable without explanation
- Whether users expect permanent progression after core recovery
- Whether a new-IP story improves acquisition, D1, D7, revenue, or App Store rank
