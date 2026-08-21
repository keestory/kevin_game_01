# Descent Breaker Ranked Endless Local Slice

- Date: 2026-08-21 KST
- Stage: 6. Implementation
- Gate: Local deterministic slice `Go`; release integration `Revise`
- Rules scope: `descent-ranked-endless-local-r2`

## Purpose

This slice validates continuous score pursuit without changing the existing Revision 5 Daily 60 / Choice Arena research path. It is an offline integrity prototype, not a public leaderboard or production monetization implementation.

## Runtime Routing

| Launch path | Mode | Ranking output |
|---|---|---|
| Normal Descent CTA | Ranked Endless | Local Clean Top 10 or Assisted PB |
| `-autoStartRankedEndless` | Ranked Endless | Test/debug path |
| Research configuration or legacy Descent UI hooks | Revision 5 Daily 60 | Existing research contract |

The two modes use separate state and finish behavior. Ranked Endless never opens Choice Arena or a 60-second result.

## Authoritative Contract

- Simulation remains fixed at 120 Hz.
- `level = tick / 7_200 + 1`; transitions do not pause input, spawn, collision, score, or effects.
- Difficulty alternates one primary pressure axis at a time and respects bounded speed/spawn/entity limits.
- Five run-local effect levels remain independent L0-L3.
- Threat tiers use both score and elapsed ticks. T1 introduces a 16-32 HP `brute`; T2 enables a telegraphed, lane-snapshot drone bolt. Enemy projectile state and attack schedules participate in checksum state.
- Ranked Endless loadouts are Swift `2 / 24t / 1,000pt/s`, Hammer `5 / 32t / 620pt/s`, and Trident `2×3 / 36t / 800pt/s`. Trident side shots cannot carry elemental effects.
- Ranked Endless electric chains from the actual impact point to 3/5/7 secondary targets for one damage each. Wind keeps its zero-damage control rule while the renderer receives immutable impact and target coordinates.
- A booster is captured once as an immutable grant snapshot before the run starts.
- A fatal combat transaction completes exactly once before a Clean checkpoint is frozen.
- A verified revive is queued and applied on the next authoritative tick.
- One run accepts at most one revive. Duplicate grant IDs are rejected.
- Once a run becomes Assisted it can never return to Clean.

## Local Integrity Boundary

The client records the run seed and quantized lane input trace. At the first fatal Clean checkpoint it replays the run in-process and compares score, tick, level, combo, danger saves, and checksum. Only a matching checkpoint may enter the local Clean Top 10.

This is useful for deterministic development QA but is not an anti-cheat security boundary. A modified client controls both the run and verifier. Public ranking requires server-issued nonce, versioned seed, signed submission envelope, idempotent Run ID, and server replay.

## Assistance Boundary

| Assistance | Prototype source | Classification | Persistence |
|---|---|---|---|
| Element L1 booster | Preflight debug choice | Assisted at tick 0 | Assisted PB only |
| Reactor +1 booster | Preflight debug choice | Assisted at tick 0 | Assisted PB only |
| Rewarded revive | DEBUG mock service | Assisted after verified grant | Assisted PB only |
| Extra life | DEBUG/local balance | Assisted after consumption | Assisted PB only |

Release builds use an unavailable rewarded-ad service and start with no free extra lives. There is no ad SDK, StoreKit product, receipt verification, transaction ledger, server-side verification, refund/reversal handling, or real-money purchase UI in this slice.

## Persistence Keys

- `descent.endless.cleanTop10`: encoded local Clean records, maximum ten.
- `descent.endless.assistedBest`: local Assisted personal best.
- `descent.endless.extraLives`: local prototype inventory; not suitable for paid value.

Clean ordering is score descending, survival ticks descending, max combo descending, then danger saves descending. Local values must never be labeled world or seasonal rank.

## Files

- `AppStoreGame/Game/DescentModels.swift`: endless state, class, assistance, booster, checkpoint and events.
- `AppStoreGame/Game/DescentRules.swift`: level/difficulty, endless step, revive and checksum rules.
- `AppStoreGame/Game/DescentGameScene.swift`: mode adapter, input trace, replay check and presentation events.
- `AppStoreGame/App/AppModel.swift`: mode routing, local partitions and mock grant orchestration.
- `AppStoreGame/Views/HomeView.swift`: local ranking card and preflight choices.
- `AppStoreGame/Views/DescentGameContainerView.swift`: level/class HUD, revive and split result UI.
- `AppStoreGameTests/DescentRulesTests.swift`: deterministic rules coverage.
- `AppStoreGameUITests/AppStoreGameUITests.swift`: preflight/class and level-boundary flow.

## Combat Pressure Presentation Boundary

- Brute reuses the owner-provided robot crop and shows a bounded numeric HP bar rather than dozens of pips.
- Drone telegraph, hostile bolt, danger line, player craft, and HP are above decorative elemental VFX in the visual priority order.
- Electric is rendered as deterministic branched arcs from the collision origin, not a player-to-target laser.
- Wind is rendered as continuous curved streams plus target spirals and arrows; destroyed source nodes cannot interrupt it because the event carries immutable coordinates.
- Skill cue roots are capped at eight. Reduce Motion uses static arc/outline cues; authoritative simulation never waits for animation.

## Release Blockers

- Server-authoritative ranking and replay do not exist.
- Real rewarded-ad and StoreKit integrations do not exist.
- A durable paid-inventory ledger does not exist.
- Ten-minute autoplay, entity/node caps, minimum-device thermals and repeated retry performance are unverified.
- The provisional 20-seed × two-minute domination screen passed at a 35% median-gap ceiling. The required three-craft 100-seed × three-minute 8% fairness Gate and ten-person ranking comprehension/retry Gates remain unverified.
- The currently imported visual assets still require the repository's provenance and commercial-rights review before release.
