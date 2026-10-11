# Copilot / AI coding instructions

This file is an always-on repository guidance entry for AI-assisted changes. Follow it in addition to the root `AGENTS.md`.

## Read first, every session

Read `AGENTS.md`, `README.md`, `docs/GAME_DESIGN.md`, and `docs/ROADMAP.md` before acting. The repository documentation is the persistent source of truth so work does not depend on prior chat context. Re-read it after context resets and before each major phase.

## Product requirements

Build the full game **Core Guardian: Demon Lord's Tower**: an offline-first Android idle tower-defense game in original stylized 2D dark-fantasy art. The player is the Demon Lord defending a Demonic Core in a 100-floor tower. Heroes invade to steal treasure and kill the Demon Lord; they must destroy the core before reaching the throne. Combat is automatic, with player-selected upgrades, guardians, evolutions, relics, research, and limited-use abilities.

The intended complete game includes:
- 100 floors, ten themed regions, milestone bosses, and a multi-phase Floor 100 invasion.
- Original guardian and hero designs, sprites/rigs, animations, portraits, skill effects, VFX, and audio.
- Role-based hero AI, party coordination, target priorities, pathfinding, boss telegraphs, and tactical difficulty scaling.
- Data-driven turrets, traps, shields, summons, core evolution paths, relics, and permanent research.
- Endless survival, prestige, local versioned save data, offline earnings capped initially at 8 hours, and duplicate-claim prevention.
- Responsive Android UI, accessibility/readability settings, effect-quality options, and documented build instructions.

## Implementation rules

- Inspect actual repository state before deciding the engine or replacing files. Godot 4/GDScript is the recommended target unless the existing project proves otherwise.
- Prefer small, complete, tested milestones over unverified mass changes.
- Do not create fake buttons, mock-only screens, dummy combat, or placeholder assets and call them finished.
- Keep content data-driven and systems modular.
- Separate combat simulation from animation.
- Do not add mandatory networking, sign-in, or cloud saves to the initial release.
- Do not expose or commit secrets.
- Tests and build checks must be executable and relevant to the current project.

## CI/APK truthfulness

Inspect the exact latest relevant workflow. Wait for queued/running runs; never call those successful. For failure, read real logs, fix the cause, rerun, and inspect the new result. A successful workflow is not proof of device installation or gameplay. Verify artifact existence, APK integrity/package metadata, installation, launch, save/load, and core combat separately. Never claim any step that was not actually observed.

## Roadmap discipline

Use `docs/ROADMAP.md` as the phased execution tracker. Each phase has an exit gate. Mark a checkbox complete only after evidence exists, and record commit/test/workflow/artifact links. Do not remove or shrink the 100-floor scope merely to make a phase appear complete. Report blockers instead.
