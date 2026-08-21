# Descent Breaker Ranked Endless QA Evidence

- Date: 2026-08-21 KST
- Stage / Gate: Stage 6 Implementation / local slice `Go`
- Release Gate: `Stop`

## Automated Evidence

| Check | Command / target | Result |
|---|---|---|
| Pure Swift rules | `swift test` | 86 passed, 0 failed |
| App compilation | Debug, Return-Shot-SE-QA iPhone SE Simulator, code signing disabled | Build succeeded |
| Ranked preflight / level flow | `testRankedEndlessPreflightSeparatesAssistedAndCrossesLevelBoundary` | Passed |
| Combat pressure flow | `testRankedEndlessCombatV2ExposesThreatAndHostileAttack` | Passed after making the DEBUG capture fixture hold the bolt on-screen; production projectile rules unchanged |
| Provisional craft reference | 20 seeds × 3 crafts × 14,400 ticks | Passed 35% median-gap screen; does not pass the 8% release Gate |

The rules suite covers the exact 7,199 / 7,200 / 7,201 tick boundary, threat and HP boundaries, Brute unlock/cap, Drone projectile resolution, three-craft damage/cadence/mobility, Trident center-only elemental proc, Endless electric 4/6/8 targets with the Revision 5 3-target regression, Clean/Assisted rules, checksum mutation, scheduling invariance, and background pause behavior.

## Simulator Observation

Device: iPhone SE (3rd generation), portrait 375×667 points, iOS 26.5 Simulator.

Observed:

- Home hierarchy clearly presents Ranked Endless, Clean Best, Assisted PB, Local Top 10, and one preflight CTA.
- Selecting a booster produces an `ASSISTED` HUD badge and never exposes Choice Arena.
- A Clean run crossed Level 2, then Level 3, while input and the game field continued without a result interruption.
- Score, chain, level, reactor HP, five skill levels, competitive class, BREAK FLOW state, and current lane remained distinguishable.
- Tap targets exposed accessibility identifiers and labels; the automated flow could select booster, confirm launch, and locate the class and level HUD.
- The v2 DEBUG showcase exposed T3, a 99 HP Brute, attacking Drone, hostile projectile count, electric L3, and wind L3. Direct inspection confirmed branched electric paths start at the collision origin and wind curves remain spatially continuous.
- A custom accessibility action moved the craft from lane 3 to lane 4. The Hammer card was selectable and its high-power/slow-movement/one-lane cost was readable without truncation.

Visual issue found and fixed during the inspect/repair loop:

- Brute HP initially rendered the literal string `(object.hitPoints)`. It now renders the numeric interpolated value and was rechecked in the after capture.

Visual issue noted but not release-blocking for this slice:

- The action field intentionally preserves vertical reaction distance, but low-density moments can look sparse on the SE screen. Density should be tuned only after no-input agency and performance reference runs; adding decorative hazards now would compromise readability and validation.

Existing build warning:

- The asset catalog reports an unassigned AppIcon child named `AppIcon 2.png`.

Final UI receipts:

- Preflight / level flow: passed in `/tmp/AppStoreGameDerivedData/Logs/Test/Test-AppStoreGame-2026.08.21_14-01-29-+0900.xcresult`.
- Combat pressure flow: passed in `/tmp/AppStoreGameDerivedData/Logs/Test/Test-AppStoreGame-2026.08.21_14-06-54-+0900.xcresult`.

## Screenshots

- `docs/screenshots/descent-2026-08-21-ranked-endless/home-se.png`
- `docs/screenshots/descent-2026-08-21-ranked-endless/level-2-clean-se.png`
- `docs/screenshots/descent-2026-08-21-ranked-endless/level-progression-clean-se.png`
- `docs/screenshots/descent-2026-08-21-combat-balance/endless-threat-v2-after.png`
- `docs/screenshots/descent-2026-08-21-combat-balance/craft-tradeoffs-after.png`
- `docs/screenshots/descent-2026-08-21-combat-balance/endless-vfx-continuity-after.png`

The last two captures were taken from a live advancing run, so the visible level can be later than the filename's launch checkpoint. The UI automation assertion is the authoritative Level 2 transition evidence.

## Not Executed / Unknown

- Ten-minute deterministic autoplay and transient-node recovery.
- 100-seed × three-minute per-craft score distribution and 8% balance threshold. Only the 20-seed × two-minute 35% screen was run.
- Real-device FPS, hitch, thermals, memory and haptics.
- VoiceOver, Switch Control, Dynamic Type, Increase Contrast, Reduce Motion and photosensitivity manual matrix.
- Fatal revive overlay manual flow under real ad failure/no-fill/dismissal.
- StoreKit purchase, pending, cancel, verification, refund and restore behavior.
- Backend submission, replay, nonce, duplicate Run ID and tamper rejection.
- Ten-person Korean user comprehension and voluntary second/third-run behavior.

None of these unexecuted checks are reported as passed.

## Continuous Attack VFX Repair — 2026-08-21 KST

- Root-cause audit: the shared decoration FIFO could remove a visible electric/wind cue; the cue cap also removed the oldest active cue; wind captured pre-push coordinates then moved its entire root by a fixed 20pt; camera impulse omitted both cue and enemy-projectile roots.
- Repair: dedicated `skillCueRoot`, no active-cue eviction, post-push wind endpoints, fixed origin/path, immediate full-path visibility, bounded path-following electric pulses and wind flow markers, and synchronized camera transform.
- Pure Swift: 86/86 Pass, including `testEndlessWindCueTargetsMatchPostPushObjectCoordinates`.
- App compilation: iPhone SE iOS 26.5 Simulator Debug build Pass. Existing unassigned `AppIcon 2.png` warning remains.
- Product UI flow: `testRankedEndlessCombatV2ExposesThreatAndHostileAttack` 1/1 Pass in `/private/tmp/AppStoreGame-DescentVFX/Logs/Test/Test-AppStoreGame-2026.08.21_14-52-22-+0900.xcresult`.
- Direct image inspection: the exported current-build attachment shows electric branches connected from impact through all visible targets, wind curves terminating at target markers, and the danger line and enemy projectile remaining legible.
- Not proven: frame-by-frame L3 seven-target instant-destruction stress, 30-tick catch-up cue accounting, 10-minute recursive node recovery, Reduce Motion sequence, photosensitivity-safe 3Hz policy, and physical-device performance.
