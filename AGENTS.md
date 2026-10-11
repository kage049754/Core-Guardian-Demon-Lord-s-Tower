# AGENTS.md — Mandatory instructions for AI coding agents

## Required reading before every task

Before inspecting, planning, editing, building, or claiming status, read these project documents from the current repository branch:

1. `README.md` — project identity, full overview, core rules, and definition of done.
2. `.github/copilot-instructions.md` — mandatory coding, testing, and reporting rules.
3. `docs/GAME_DESIGN.md` — canonical detailed game design.
4. `docs/ROADMAP.md` — phases, exit gates, and current status.

Do not rely on conversation memory as a substitute. Re-read the repository files at the start of every new task/session and whenever a requirement is unclear. If documents conflict, preserve the more specific game rule and update the documents coherently rather than ignoring them.

## Project mission

Build **Core Guardian: Demon Lord's Tower**, a complete offline-first Android game: stylized 2D dark-fantasy idle tower defense across 100 floors. The player is the Demon Lord and defends a Demonic Core from invading heroes. The heroes must destroy the core before they can reach the Demon Lord. Automatic combat, strategic upgrades, original characters/art/animations/effects, hero AI, bosses, research, core evolutions, local saves, offline rewards, endless survival, and prestige are required parts of the design.

## Non-negotiable behavior

- Work directly in this repository; do not substitute a plan-only answer for requested implementation.
- Inspect the current branch, tree, existing code, build setup, and latest relevant CI run before editing.
- Preserve existing working functionality. Avoid unrelated rewrites.
- Implement complete vertical slices: functional logic, UI, content/data, persistence where needed, and tests.
- Do not leave placeholder-only screens or fake interactions and describe them as complete.
- Do not invent files, commits, test outcomes, APKs, workflow statuses, or device results.
- Never claim an APK is built or verified until the exact artifact has been inspected and the appropriate checks have passed.
- Separate CI success, APK artifact verification, installation, launch, and gameplay testing in status reports.
- Keep the first release offline-first; do not add required accounts, cloud saves, or network dependencies without changing the approved design documents first.
- Keep content modular and data-driven. New units, enemies, floors, skills, and bosses must not require rewriting the core simulation.
- Use original stylized 2D dark-fantasy assets or assets with recorded, compatible licenses. Keep attribution records.
- Do not commit secrets, private signing keys, or API credentials.
- If an existing workflow is queued or running, wait for its final state before launching a conflicting run. If it fails, inspect actual logs, fix the cause, rerun, and verify the new result.
- Update roadmap checkboxes only with evidence. Link the commit, test, run, or artifact when possible.

## Required work loop

1. Read all required docs.
2. Inspect repository and relevant files, recent commits, branch, workflows, and current CI state.
3. Identify the smallest complete next milestone and its acceptance tests.
4. Implement and test directly in the repo.
5. Commit changes with a descriptive message.
6. Monitor the exact workflow run to completion when possible; pending/running is not success.
7. If failed, inspect logs, fix, and rerun.
8. Inspect the APK artifact and metadata if the workflow produces one.
9. Run or arrange Android installation/launch/gameplay smoke tests where available; do not conflate them with CI.
10. Update `docs/ROADMAP.md` with evidence-based status and remaining blockers.

## Required technical quality

- Keep combat simulation authoritative and separate from animation/rendering.
- Use data-driven unit, enemy, skill, wave, floor, relic, and research definitions.
- Make save data versioned, migrated, atomic, and recoverable.
- Bound offline earnings and prevent duplicate claims.
- Test defeat, floor completion, boss phases, upgrade costs, save/load, migrations, offline time boundaries, and resource duplication.
- Optimize AI decision cadence, projectile/effect pooling, and mobile memory/performance.
- Use readable mobile UI, appropriate touch targets, and reduced-effects options.
- Do not mark the game complete until every Definition of Done item in README.md is satisfied.

## Required status report

Every implementation update must state:
- Exact repository and branch.
- Files changed and what actually changed.
- Tests executed and results.
- Exact GitHub Actions run status and URL, if run.
- Artifact name/link and verification performed, if available.
- Physical-device test status separately.
- Roadmap phase completed, next phase, and blockers.

If a capability cannot be performed with available tools, state that limitation accurately and complete the other verifiable work.
