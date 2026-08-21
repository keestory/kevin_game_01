# Descent Breaker Ranked Endless Concept

- Version: Local vertical slice v0.3 — Combat Pressure
- Date: 2026-08-21 KST
- Stage: 6. Implementation
- Gate: Local vertical slice `Go`; Product Validation `Revise`; public leaderboard and real monetization `Stop`
- Authority: This proposal does not change the active `descent-breaker.product-spec.md` revision 5 or its BREAK FLOW research contract.

## 1. Decision

Descent Breaker should not stop for chapters or force narrative progression. Its primary fantasy is:

> 끝없이 내려오는 위협을 파괴하며, 지난 나와 가까운 경쟁자를 추월하고 세계 1위를 쫓는다.

The product direction is a ranking-first continuous action game with two complementary competitive modes.

1. `RANKED ENDLESS` is the aspirational main mode and determines the official seasonal number one.
2. `DAILY 60` is the low-commitment equal-condition score attack that creates an easy daily return.

The current 60-second revision 5 remains the research baseline until this pivot passes a separate vertical-slice Gate.

Implementation note: the normal home CTA now opens the local Ranked Endless slice. Revision 5 remains isolated behind research and legacy UI-test launch arguments, so this implementation does not replace or contaminate the approved Choice Arena research contract.

## 2. Continuous Core Loop

1. Select a craft.
2. Enter a deterministic ranked run.
3. Drag across five lanes while the craft fires automatically.
4. Destroy falling objects, collect elemental cores, build direct-hit chains, and activate BREAK FLOW.
5. Every 60 seconds, `LEVEL` increases without pausing input, simulation, spawn, or score.
6. Difficulty rises within bounded limits and the environment crossfades into a new `SECTOR` mood.
7. The run ends only when reactor HP reaches zero.
8. Confirm SCORE, LEVEL, MAX CHAIN, PB improvement, and verified rank change.
9. Press one CTA: `다시 추격`.

There is no chapter result screen, narrative modal, mission dialogue, or forced reward-claim step during the run.

## 3. What SCORE, LEVEL, and SECTOR Mean

### SCORE

SCORE is the only primary ranking value. It preserves the current base score, combo, Danger Save, redline decision if retained in a later non-blocking form, and BREAK FLOW contribution. A hidden activity penalty or level multiplier must not be added.

Leaderboard order:

1. Verified score, descending
2. Survival ticks, descending
3. Maximum combo, descending
4. Danger saves, descending
5. Exact ties share the same public rank

### LEVEL

LEVEL is run-local difficulty and survival progress. It is not account XP, permanent power, or a purchasable stat.

- `LEVEL 1`: 0-59 seconds
- `LEVEL 2`: 60-119 seconds
- `LEVEL 3`: 120-179 seconds
- Continue until reactor failure

The transition is a small non-blocking label. It never opens a result, choice, or story screen.

### SECTOR

SECTOR is an ambient visual distance marker across several levels. It may change background, color temperature, particles, and environmental audio, but not authoritative score or physics by itself.

Proposed rotating moods:

- 상공 잔해대
- 강철 회랑
- 코어 폭풍권
- 붉은 고도
- 심층 방어선

Reaching the final mood does not end the game. Higher numbered variants continue.

## 4. Difficulty Contract

Difficulty must rise enough to end skilled runs without turning into an unbounded performance or fairness problem.

- Ranked Endless uses a separate v2 combat contract; Revision 5 / Daily 60 keeps its existing HP, cadence, and checksum fixtures.
- Threat is `min(6, max(scoreBand, timeBand))`, so strong scoring brings danger forward while the time floor prevents intentional low-score stalling from freezing difficulty.
- Score bands are `<4,000 / 4,000 / 10,000 / 25,000 / 50,000+`; the time floor reaches T1 at 30 seconds and T2 at Level 2.
- `brute` begins at T1 with 16 HP and rises to a capped 32 HP. It is slower than normal and replaces at most 20% of deterministic regular spawns.
- `drone` begins firing at T2. It snapshots the player's current lane after a 90-tick warning, fires one dodgeable bolt for one reactor damage, and shares the breach damage cooldown.
- Base Endless HP is normal 4, armored 10, spike 6, drone 6, core 6, then rises in bounded two-tier steps. Core HP remains capped at 8 so skill acquisition is not starved.
- Existing speed and spawn-interval caps remain; HP and enemy projectiles have explicit caps instead of unbounded scaling.
- Speed, minimum spawn interval, concurrent entity count, and simultaneous effect count require explicit caps.
- Score receives no level multiplier; higher levels already offer more scoring opportunities through pressure.
- Reactor HP, ship DPS, core pickup rules, and skill ranks reset only when the full run ends, not at each level.

Exact level values are unknown until deterministic bot and human playtesting. Do not market an unlimited maximum level before long-run performance is verified.

## 5. Ranking Product

### Primary: Ranked Endless Season

- 28-day season
- Same rules version and deterministic seed schedule
- No rewarded-ad revive, paid power, booster, or purchased extra attempt
- Highest verified clean-run score per player is the season entry
- Season rank resets; personal PB and Hall of Fame remain
- Never show a fake player, fake score, or simulated world rank

Ship fairness is unresolved. During validation, use ship-specific boards. A combined board is permitted only after long-run reference tests show that no craft's median score is more than 8% ahead; an official championship should target a tighter 2% practical gap. A featured-craft season is the fallback when combined balance is not credible.

Current local v2 loadouts are deliberately asymmetric:

| Craft | Damage / volley | Fire interval | Max movement | Advantage | Cost |
|---|---:|---:|---:|---|---|
| Swift S-1 | 2×1 | 24 ticks | 1,000 pt/s | fastest precision tracking | one lane, low burst |
| Hammer H-2 | 5×1 | 32 ticks | 620 pt/s | strongest single hit | slowest movement, one lane |
| Trident T-3 | 2×3 | 36 ticks | 800 pt/s | three-lane coverage | lowest single-target DPS; only center shot carries elemental effects |

The 20-seed, two-minute local reference is only a provisional domination screen with a 35% median-gap ceiling. It passed after rejecting slower Hammer candidates that made it noncompetitive and an equal-cadence Hammer candidate that became dominant. It does not satisfy the 100-seed × three-minute, 8% combined-board Gate.

### Secondary: Daily 60

- One fixed KST daily seed and featured craft
- Exactly 60 seconds
- One best verified score per player per day
- No streak loss, missed-day punishment, paid attempt, or cumulative participation bonus
- Daily score never adds to the Ranked Endless score

Daily 60 gives a fair, short entry point. Ranked Endless remains the prestige destination.

### Rank motivation hierarchy

Do not show only a distant world number one. The result hierarchy is:

1. `NEW BEST +4,210`
2. `8,421위 → 7,980위`
3. `TOP 10%까지 3,200점`
4. `WORLD #1까지 928,400점`
5. CTA `다시 추격`

The player first beats the past self, then a nearby rival, then sees the world leader.

## 6. Story Policy

Story is ambient only.

Home premise:

> 하늘은 계속 무너진다. 당신은 어디까지 버틸 수 있는가.

During play there are no characters, dialogue, chapters, missions, cutscenes, AI chatter, story unlocks, or ending. Falling wreckage, reactor state, effects, level labels, sector background, and sound carry the world.

Do not claim that a city was permanently saved. The Descent continues after every run.

## 7. Competitive Integrity

Public rank requires server-authoritative replay verification. The client final score is never trusted.

Minimum ranked submission:

- Run ID and server-issued nonce
- Rules version, seed schedule, build, and craft
- Quantized input changes with authoritative ticks
- Level checkpoint checksums
- Final score, survival ticks, and checksum
- Pause, background, interruption, and continue flags

The server replays the 120 Hz simulation and recalculates score and checksum. Invalid revision, seed, nonce, payload, score, or checksum fails closed. Duplicate Run IDs are idempotent.

Until that service exists, the product may show local PB and a local verified top ten only. It must not label a local or fabricated value as `WORLD RANK`.

## 8. Ads, Purchases, and Assisted Play

Rewarded revive, extra lives, and paid boosters are approved product-direction candidates. They coexist with ranking through an explicit competitive-class boundary.

| Feature | Clean Ranked | Assisted Endless |
|---|---|---|
| Official seasonal number one | Eligible | Not eligible |
| Rewarded-ad revive | Clean score freezes at fatal tick; continuation becomes Assisted | One total revive per run in the first slice |
| Purchased extra-life token | Equipping or consuming is not Clean | May replace the ad revive within the first-slice total cap |
| Paid booster | Equipping before launch marks the run Assisted immediately | One immutable pre-run booster snapshot |
| Result | Verified Clean score and rank | Assisted PB, assist signature, and extra active time |

### Transition contract

1. A run that starts without extra life or booster is `clean`.
2. On fatal tick, complete all authoritative hit, drop, breach, score, and checksum transactions exactly once.
3. Freeze and submit the Clean result at that checkpoint.
4. If the player declines assistance, times out, or receives no verified grant, end the run normally.
5. If a rewarded-ad or extra-life grant is verified, permanently change the same Run ID to `assisted` and resume on the next authoritative tick.
6. The later Assisted score can never overwrite or enter the Clean board.

Equipping an extra life or booster marks the run Assisted before play, even if the item is never consumed. Otherwise merely holding an advantage would create an untracked strategic benefit.

### Initial limits

- Total revive cap: one per run, supplied by either rewarded ad or owned extra-life token
- Booster cap: one per run, selected before launch
- Rewarded-ad completion cap: start testing at three per session
- No forced interstitial
- No repeat offer after the player declines in the same run
- No purchase pressure or countdown at the fatal screen; extra-life tokens are acquired outside the death moment

Candidate bounded boosters include `start with one elemental core at L1` and `one additional reactor guard`. Score multiplier, automatic aiming, permanent fall-speed reduction, unlimited continue, and direct season-point purchase are rejected.

Assisted results begin as personal PB only. A clearly labeled Assisted leaderboard may be tested later, partitioned by the exact authoritative assistance signature. It is never the official world-number-one board and must be removed if spending and rank become effectively monotonic.

### Store and ad integrity

- Digital lives and boosters use StoreKit In-App Purchase.
- A verified transaction ID is the idempotency key; persist the grant before finishing the transaction.
- Consumable balances require a durable ledger and are not restored from UserDefaults alone.
- Pending, cancelled, unverified, offline, no-fill, show-failure, close-without-reward, duplicate, or stale callbacks grant nothing.
- Rewarded-ad grants require exactly-once impression or server-side-verification identity.
- Ad and StoreKit callbacks enqueue a typed authoritative grant; they never mutate gameplay state directly.
- Refund and reversal update unused balance or future entitlement but never rewrite a completed run or checksum.
- ATT consent cannot be a condition for receiving the gameplay reward.
- Any ad SDK requires privacy manifest, signature, data-transfer, ATT, retention, and deletion review before release.

## 9. Minimum Vertical Slice

Before building a backend leaderboard, create one offline `descent-endless-r1` slice.

- Endless until reactor failure
- At least Levels 1-3 in a three-minute target run
- Current three crafts, five persistent effects, and BREAK FLOW
- No Choice Arena pause, story, progression currency, or research logger
- Same fixed seed and local verified top ten
- In-process replay verifier
- Mock rewarded-ad service, StoreKit Test extra-life and booster products, and local Assisted PB
- Existing revision 5 research launch completely bypasses the endless mode

### Technical Gate

- 7,199 / 7,200 / 7,201 tick level boundaries match across 30, 60, and 120 Hz scheduling and large-delta batching.
- Ten-minute autoplay has zero crash, NaN, integer overflow, out-of-bounds entity, or entity-cap breach.
- Replay rejects modified input, revision, seed, final score, or checksum.
- Fatal checkpoint, decline, verified revive, duplicate callback, stale callback, and booster snapshot are deterministic and replayable.
- One Run ID produces at most one final Clean submission; Assisted score never enters the Clean partition.
- Three-craft 100-seed long-run median score gap is at most 8% before combined-board consideration.
- No-input median score is at most 75% of the active reference.
- Minimum-device hard floor is 30 fps with a 60 fps target.
- Story, endless UI, progression writes, and events are zero in the revision 5 research launch.

### User Gate

With ten new Korean iPhone casual-action users:

- At least 8 of 10 explain the ranking rule correctly.
- At least 6 of 10 voluntarily start a second ranked run.
- At least 6 of 10 voluntarily start a third run.
- At least 6 of 10 improve Run 3 score by 20% or more over Run 1.
- Median active-touch time is at least 60%.
- At least 8 of 10 rate the competition as understandable and fair.
- At least 8 of 10 explain that advertising, extra lives, and boosters cannot create the official Clean number one.

These are directional thresholds. D1, D7, revenue, and App Store rank remain unknown until a measured cohort exists.

## 10. Stop Conditions

- Any unverified or fabricated score appears on a public board.
- Ads, payment, craft imbalance, background manipulation, or continue changes Clean rank.
- One Assisted result is misclassified as Clean.
- No-input score exceeds 75% of the active reference.
- One craft owns a median score advantage above 8% in validation.
- Level or sector transition pauses input or authoritative ticks.
- Long-run entity, performance, integer, or checksum limits fail.
- At least 2 of 10 users abandon retry because competition feels manipulated or unwinnable.
- Ranked exposure performs worse than PB-only on voluntary third run or measured D1.
- At least 2 of 10 conclude that money can buy the official number-one position.
- The team must add forced grind, permanent power, or fake competitors to sustain engagement.

## 11. Agent Conflict and Orchestrator Decision

- Strategy / Growth recommended 60-second score attack as the safest primary because it minimizes time advantage and fits the current rules.
- Narrative / Product Planning recommended continuous endless because it best matches the requested uninterrupted fantasy.
- Engineering / QA confirmed that endless is feasible only as a new authoritative mode with long-run deterministic, performance, and replay work.
- Product Orchestrator decision: keep both but give them different jobs. Ranked Endless is the aspirational primary; Daily 60 is the fair low-friction secondary. Prototype offline Endless first and defer public ranking until verification exists.

## 12. Implemented Local Slice Evidence

Implemented on 2026-08-21 KST:

- Endless play continues past 60 seconds with a non-blocking level increase every 7,200 authoritative ticks.
- Difficulty alternates one bounded pressure axis at a time and reuses the approved carrier/core loop.
- A no-booster run starts `Clean`; selecting a pre-run booster, consuming an extra life, or accepting a verified mock rewarded revive makes the run permanently `Assisted`.
- The first fatal Clean checkpoint is replayed in-process from the run seed and quantized input trace before it can enter the local Clean Top 10.
- Assisted continuation resumes on the next authoritative tick, is capped at one revive, and writes only an Assisted personal best.
- The preflight, HUD, revive overlay, and result screen expose the competitive class instead of hiding assistance.
- Public world rank, ad SDK, StoreKit transaction ledger, backend nonce/submission, and server replay are intentionally not implemented.

Observed verification:

- SwiftPM: 85 tests passed, 0 failed, including the v2 threat, enemy projectile, craft, elemental-proc, and provisional 20-seed balance contracts.
- Xcode Debug iPhone SE Simulator build: succeeded.
- iPhone SE (3rd generation) UI automation: home → preflight → booster → Assisted run, level-boundary → Level 2 Clean run, and the T3 combat showcase were exercised.
- Simulator inspection: T3, Brute numeric HP, Drone telegraph/bolt, electric branches, continuous wind, danger line, craft trade-offs, and accessibility lane movement remained legible at 375×667 points.

This evidence passes only the local Stage 6 slice. Ten-minute autoplay, 100-seed × three-minute craft balance at the 8% public-board threshold, ten-person comprehension/retry tests, minimum-device performance, real ad/IAP failure handling, and public anti-cheat remain open Gates.
