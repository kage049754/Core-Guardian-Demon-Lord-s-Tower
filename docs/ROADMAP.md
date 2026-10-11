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
- [ ] Produce a real minimal APK; inspect package metadata and artifact integrity.
- [ ] Install and launch on a compatible Android device if device access is available.

**Exit gate:** a real APK artifact exists, can be retrieved, and its package metadata and install/launch status are documented. Do not mark this gate complete based on CI status alone.

## Phase 1 — Playable combat foundation

- [ ] Initial battle scene, core health, automatic core attacks, guardian damage, enemy movement, targeting, damage, cooldowns, and defeat handling are present; this item remains open until the complete acceptance test suite passes.
- [ ] Initial automatic attacks and wave spawning/completion logic exist; multi-wave encounter flow and validation remain incomplete.
- [ ] Implement win, defeat, pause, restart, and a real upgrade choice.
- [ ] Add automated gameplay tests for damage, targeting, cooldowns, wave completion, and core destruction.
- [ ] Export and verify an Android build.

**Exit gate:** one complete playable floor with a functional defeat and victory loop, not a static demonstration.

## Phase 2 — Original art and animation

- [ ] Define visual style, palette, sprite scale, outline, and asset pipeline.
- [ ] Create original core, environment, guardian, enemy, projectile, and UI art.
- [ ] Implement idle, walk, attack, cast, hit, stun, and death states.
- [ ] Integrate projectile trails, impact bursts, shields, runes, status indicators, and damage feedback.
- [ ] Verify animation follows real simulation state.
- [ ] Track third-party asset/font/audio licenses and attribution.

**Exit gate:** combat uses integrated readable art and animation; placeholders are not presented as finished assets.

## Phase 3 — Hero AI and defensive strategy

- [ ] Implement role-based enemy priorities and stable retargeting.
- [ ] Implement party formations, healer support, ranged positioning, and boss skill timing.
- [ ] Implement pathfinding around blockers and alternate routes where the map supports them.
- [ ] Add Soul Turret, Rift Trap, Void Ward, and Summoning Gate.
- [ ] Add player skills and status effects.
- [ ] Add first multi-phase boss with clear telegraphs.
- [ ] Test AI behavior, structure targeting, and viable defense builds.

**Exit gate:** several viable defensive builds can complete the same encounter, and hero behavior is meaningfully tactical.

## Phase 4 — Floors 1–10 and progression

- [ ] Implement The Outer Gate, ten playable floors, data-driven waves, and Knight-Captain boss.
- [ ] Add floor map, rewards, results screen, unlock rules, and replay behavior.
- [ ] Add initial guardian collection and bestiary.
- [ ] Test all floor links, boss conditions, rewards, and progression persistence.

**Exit gate:** floors 1–10 are playable and replayable with tested progression.

## Phase 5 — Saves, research, and idle systems

- [ ] Implement versioned local save schema and migrations.
- [ ] Implement atomic writes and corrupted-save recovery.
- [ ] Implement the five permanent research branches.
- [ ] Implement offline earnings and a configurable cap, initially 8 hours.
- [ ] Ensure combat waves and bosses do not advance offline in the first release.
- [ ] Prevent duplicate offline claims and resource duplication.
- [ ] Implement prestige with explicit reset preview and confirmation.
- [ ] Test force-stop/reopen, migrations, interrupted writes, offline time boundaries, and defeat persistence.

**Exit gate:** progress survives app restarts, offline rewards are bounded and claimable once, and permanent progression survives defeat.

## Phase 6 — Full 100-floor campaign

- [ ] Implement all ten regions and floor data for floors 1–100.
- [ ] Implement all milestone bosses and their distinct phases/mechanics.
- [ ] Expand original guardian, enemy, skill, relic, and evolution roster.
- [ ] Implement Infernal, Abyssal, and Soulbound Core paths.
- [ ] Implement relic loadouts, achievements, and permanent unlocks.
- [ ] Implement the four-hero Legendary Hero Party and multi-stage Floor 100 encounter.
- [ ] Unlock endless survival after campaign victory.
- [ ] Validate every floor's data, progression path, rewards, and completion conditions.

**Exit gate:** all 100 floors can be reached and completed under the intended rules, with no missing encounters or progression softlocks.

## Phase 7 — Optimization and release

- [ ] Profile large enemy waves, AI updates, pathfinding, VFX, memory, and battery usage.
- [ ] Add projectile/effect pooling and reduced-effects settings where needed.
- [ ] Test narrow screens, touch targets, pause/resume, background/foreground, and system navigation.
- [ ] Test save recovery and offline calculations on Android.
- [ ] Produce release and debug APKs as appropriate; keep signing secrets out of Git.
- [ ] Verify final artifact exists, is retrievable, has correct package metadata, and installs.
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
- [x] Godot 4 project, main battle scene, and initial combat loop committed.
- [x] Data file with 100 campaign floor definitions and ten milestone bosses committed; runtime reads floor region and boss names.
- [x] Initial guardian and enemy archetype data files committed.
- [x] Godot project validation workflow has completed successfully on earlier commits. Re-check the latest commit before relying on that result.
- [ ] Android export workflow has not yet produced a verified APK; previous runs failed during Android SDK setup or export configuration, and fixes are being tested.
- [ ] Phase 0 exit gate: APK produced, metadata checked, and installation/launch status recorded.
- [ ] Phase 1 exit gate: complete playable floor, full combat acceptance tests, and verified Android build.

**Current phase:** Phase 0 / Phase 1 foundation. Do not mark either phase complete until its exit gate passes. Documentation and data files are not proof that every designed mechanic is implemented.
