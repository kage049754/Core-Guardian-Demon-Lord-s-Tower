# Development roadmap — Core Guardian: Demon Lord's Tower

This is the canonical implementation sequence. The scope is a complete 100-floor offline-first Android game, not a menu-only prototype. See [GAME_DESIGN.md](GAME_DESIGN.md) for full gameplay, character, AI, art, boss, progression, save, and UI requirements.

## Status legend

- [ ] Not started / no evidence recorded
- [x] Completed only when repository changes and verification evidence exist
- A planned feature, code stub, mock screen, pending workflow, or old successful run is not completion evidence.

## Phase 0 — Repository and build foundation

- [x] Inspect repository tree, current branch, engine/project files, workflow files, and existing CI status.
- [x] Confirm Godot 4 / GDScript as the initial engine target.
- [x] Add Android export preset, debug-signing setup, and a CI workflow; export still needs to pass.
- [x] Add Godot import/startup validation workflow. Gameplay-specific automated tests remain incomplete.
- [x] Produce a debug APK and verify package metadata and archive integrity (run [#38153537513](https://github.com/kage049754/Core-Guardian-Demon-Lord-s-Tower/actions/runs/38153537513), commit `1ca22bfba54edd7ceb1158774d34b2a052b66513`).
- [ ] Install and launch on a compatible Android device if device access is available.

**Exit gate:** a real APK artifact exists, can be retrieved, and its package metadata and install/launch status are documented. Do not mark this gate complete based on CI status alone.

## Phase 1 — Playable combat foundation

- [x] Initial battle scene, core health, automatic core attacks, guardian damage, enemy movement, targeting, damage, cooldowns, and defeat handling are implemented and pass Godot parse/startup checks; combat-specific acceptance tests remain open.
- [x] Multi-wave floor progression, boss-floor spawning, floor-clear state, defeat/retry, and explicit next-floor flow are implemented; full combat playthrough validation remains open.
- [x] Implement floor clear, core defeat/retry, pause-to-menu, new game, and real upgrade choices. Full-device playtesting remains open.
- [ ] Add automated gameplay tests for damage, targeting, cooldowns, wave completion, and core destruction.
- [x] Export and verify a debug Android APK artifact on the current implementation checkpoint.

**Exit gate:** one complete playable floor with a functional defeat and victory loop, not a static demonstration.

## Phase 2 — Original art and animation

- [ ] Define visual style, palette, sprite scale, outline, and asset pipeline.
- [ ] Original hero atlas and Outer Gate background SVG are integrated, with procedural core, turrets, traps and combat effects. Complete distinct guardian sprites and production art for all regions remain open.
- [ ] Implement idle, walk, attack, cast, hit, stun, and death states.
- [ ] Integrate projectile trails, impact bursts, shields, runes, status indicators, and damage feedback.
- [ ] Verify animation follows real simulation state.
- [ ] Track third-party asset/font/audio licenses and attribution.

**Exit gate:** combat uses integrated readable art and animation; placeholders are not presented as finished assets.

## Phase 3 — Hero AI and defensive strategy

- [x] Implement role-based enemy stats, nearest-target core/turret attacks, ranger standoff attacks, mage bursts, healer support, assassin speed and siege-golem durability.
- [ ] Healer support, ranged positioning and boss skill timing are implemented; full party formations and coordinated pathfinding remain open.
- [ ] Implement pathfinding around blockers and alternate routes where the map supports them.
- [ ] Soul Turret and Rift Trap are implemented and upgradeable; Void Ward and Summoning Gate remain open.
- [ ] Emergency Shield is implemented; the remaining active skills and complete status-effect suite remain open.
- [x] Add boss attack telegraphs and phase-scaled damage. Distinct mechanics for every milestone boss remain open.
- [ ] Test AI behavior, structure targeting, and viable defense builds.

**Exit gate:** several viable defensive builds can complete the same encounter, and hero behavior is meaningfully tactical.

## Phase 4 — Floors 1–10 and progression

- [ ] Data for all 100 floors, ten regions and ten milestone bosses exists, and the tower map is implemented. Full playable encounter testing for floors 1–10 remains open.
- [ ] Tower map, basic rewards and floor unlock/retry flow exist; a dedicated results screen and verified replay behavior remain open.
- [ ] Add initial guardian collection and bestiary.
- [ ] Test all floor links, boss conditions, rewards, and progression persistence.

**Exit gate:** floors 1–10 are playable and replayable with tested progression.

## Phase 5 — Saves, research, and idle systems

- [x] Implement versioned local save schema (version 3) with defaults for older saves.
- [x] Implement temporary-file writes, backup rename/restore and save-version validation; corruption recovery still needs automated fault-injection tests.
- [x] Implement selectable permanent research branches with distinct core, guardian, engineering, idle-income and ability-cooldown effects.
- [x] Implement offline gold earnings capped at 8 hours and a return summary.
- [x] Combat does not advance while the app is closed.
- [x] Save a new timestamp immediately after calculating offline rewards; additional exploit and boundary tests remain open.
- [x] Implement prestige eligibility at endless floor 120, a reset preview, Demon Seals, and retention of permanent research/relics.
- [x] Automated tests cover save/load restoration, two-minute offline earnings, duplicate-claim prevention, and achievement persistence. Force-stop/reopen on a physical device, save fault-injection, migration edge cases, and defeat persistence remain open.

**Exit gate:** progress survives app restarts, offline rewards are bounded and claimable once, and permanent progression survives defeat.

## Phase 6 — Full 100-floor campaign

- [x] Define all 100 campaign floors, ten regions and ten boss milestones in data. Unique encounters and region-specific environments remain open.
- [x] Implement distinct combat mechanics for all ten milestone bosses and add automated checks for representative healing, shield dispel, displacement, and coordinated-party attacks. Unique multi-stage phases and full balance tuning remain open.
- [ ] Expand original guardian, enemy, skill, relic, and evolution roster.
- [ ] Implement Infernal, Abyssal, and Soulbound Core paths.
- [x] Implement a three-slot equipped relic loadout, permanent achievement definitions, unlock tracking, and local-save persistence. Additional achievements and balance tuning remain open.
- [ ] Floor 100 spawns a four-role Legendary Hero Party with boss telegraphs; authored multi-stage party mechanics remain open.
- [x] Unlock endless floors after the 100-floor campaign and support milestone bosses every tenth endless floor.
- [ ] Validate every floor's data, progression path, rewards, and completion conditions.

**Exit gate:** all 100 floors can be reached and completed under the intended rules, with no missing encounters or progression softlocks.

## Phase 7 — Optimization and release

- [ ] Profile large enemy waves, AI updates, pathfinding, VFX, memory, and battery usage.
- [ ] Add projectile/effect pooling and reduced-effects settings where needed.
- [ ] Test narrow screens, touch targets, pause/resume, background/foreground, and system navigation.
- [ ] Test save recovery and offline calculations on Android.
- [ ] Produce release and debug APKs as appropriate; keep signing secrets out of Git.
- [x] Verify the debug APK artifact is retrievable and has correct package metadata/archive integrity. Physical-device installation remains unverified.
- [ ] Smoke-test startup, battle, upgrades, core destruction, victory, save/load, and offline rewards on a device where possible.
- [ ] Document setup, build commands, release procedure, limitations, and known issues.

**Exit gate:** all required automated checks pass, the exact final APK is verified, and device-test results are reported separately from CI.

## Continuous implementation / CI workflow

For each scoped milestone:

1. Read `AGENTS.md`, `README.md`, `.github/copilot-instructions.md`, this roadmap, and `docs/GAME_DESIGN.md`.
2. Inspect current repository files, branch, recent commits, workflows, and latest relevant run.
3. If a run is queued/running, wait for its final status before starting a conflicting run.
4. Implement the smallest complete feature slice and add tests.
5. Commit and push the change.
6. Monitor the exact new workflow run until completed when tool/session limits allow.
7. If failed, inspect the actual logs, fix the cause, and rerun.
8. Verify the resulting APK artifact and metadata; do not infer existence from a green build alone.
9. Separate CI, artifact, install, launch, and gameplay verification in the report.
10. Update this roadmap with evidence and blockers, then continue to the next phase.

## Current verified status

- [x] Repository identified as `kage049754/Core-Guardian-Demon-Lord-s-Tower`, default branch `main`.
- [x] Godot 4 project with battle scene, menu, HUD, tower map, collection/settings screens, and reduced-effects toggle.
- [x] Data files define all 100 floors, ten regions, ten milestone bosses, five guardians, eight enemy archetypes, five research branches, three core evolution branches, six relics, and nine achievements.
- [x] Core attacks, Soul Turrets, Rift Traps, role-based hero AI, multi-wave floors, ten distinct milestone boss mechanics, four-role Floor 100 invasion, three core evolutions, three-slot relic loadout, achievements, versioned local saves, capped offline rewards, endless survival, prestige, and unlocked-floor replay are implemented.
- [x] Automated gameplay tests cover combat, boss mechanics, research, core evolution, save/load, offline reward boundaries and duplicate claims, relic loadout limits, achievement persistence, fresh-save reset, replay progress preservation, Floor 100 victory, and Endless Spire unlock.
- [x] Godot validation passed on commit `32d59a75ec091317add9cf033caee36d9cb463a9`: [validation run](https://github.com/kage049754/Core-Guardian-Demon-Lord-s-Tower/actions/runs/38155895991).
- [x] Android debug APK built and verified on commit `32d59a75ec091317add9cf033caee36d9cb463a9`: [build run](https://github.com/kage049754/Core-Guardian-Demon-Lord-s-Tower/actions/runs/38155895992), [artifact](https://github.com/kage049754/Core-Guardian-Demon-Lord-s-Tower/actions/runs/38155895992/artifacts/11708358222). Package `com.coreguardian.demonlordstower`, version `0.1.0`, min SDK 21, target SDK 34, ARM64; ZIP/APK archive integrity passed. APK SHA-256: `e3acdbb033f99245d3940a402659661bc87ae25ffe2b04297fbfc8d0f003d125`.
- [ ] Physical-device installation, launch, touch-control feel, performance, and gameplay testing have not been performed.
- [ ] Full campaign balance/playthrough, unique multi-stage boss phases, expanded skill VFX/audio, save fault-injection, device performance profiling, and final release packaging remain incomplete.

**Current status:** The current debug APK is verified and automated progression tests pass. The full release remains in progress; continue remaining roadmap phases and do not claim physical-device verification.
