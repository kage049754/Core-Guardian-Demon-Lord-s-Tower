# Core Guardian: Demon Lord's Tower

> **A 100-floor, offline-first Android idle tower-defense game in stylized 2D dark fantasy. You are the Demon Lord. Defend your Demonic Core against heroes climbing your tower to steal your treasure and kill you.**

**Project status:** Godot implementation is underway. The game now includes an initial 360-degree defense loop, multi-wave floor progression, role-based hero behavior, upgradeable Soul Turret/Rift Trap, guardian progression, selectable research, core evolutions, relics, local versioned saves, capped offline rewards, a 100-floor map, endless survival, and prestige. A debug APK has been built and its package metadata/archive integrity verified at [GitHub Actions run #38153537513](https://github.com/kage049754/Core-Guardian-Demon-Lord-s-Tower/actions/runs/38153537513). Physical-device testing and several roadmap systems remain incomplete; see [the roadmap](docs/ROADMAP.md).

## Project identity

- **Title:** Core Guardian: Demon Lord's Tower
- **Genre:** Idle tower defense, incremental progression, dark-fantasy strategy
- **Platform:** Android
- **Art direction:** Original stylized 2D dark fantasy
- **Campaign:** 100 floors across ten themed regions
- **Combat:** Automatic defense simulation; the player chooses upgrades, unit compositions, evolutions, and limited-use abilities
- **Core defeat condition:** Heroes destroy the Demonic Core; the floor is breached and the run ends
- **Connectivity:** Offline-first. No account or network connection required for the core game
- **Long-term modes:** Campaign, endless survival, and prestige
- **Engine target:** Godot 4 with GDScript, subject to repository/build-environment verification

## High concept and story

You are the ancient Demon Lord and owner of a legendary 100-floor tower filled with treasures, forbidden magic, and powerful guardians. Heroes invade to steal your riches, earn glory, and claim the bounty on your head. Kingdoms send increasingly powerful parties as rumors of your treasure spread.

Your objective is to protect the Demonic Core, strengthen the tower, defeat every invading party, and prevent the heroes from reaching your throne. Each floor has a core, defensive structures, and enemy entry points. If the core is destroyed, the defenses collapse and the heroes gain access to the Demon Lord's throne.

## Core gameplay loop

1. Heroes invade a floor in waves.
2. The core, guardians, turrets, traps, and summons fight automatically.
3. The player chooses upgrades, spends resources, and activates limited-use skills.
4. Defeated heroes provide gold, souls, relic fragments, and progression rewards.
5. Clear the required encounter to unlock the next floor.
6. Invest in permanent research and unit evolutions.
7. If a core is destroyed, end the current run while preserving eligible permanent progression.
8. Complete all 100 floors, then unlock endless survival and deeper prestige progression.

Combat must be a real simulation, not a visual mockup. The combat simulation owns health, damage, cooldowns, targeting, status effects, wave completion, and win/loss conditions. Animations must reflect simulation state and must not determine combat outcomes.

## The 100-floor campaign

| Floors | Region | Boss / encounter | Signature mechanics |
|---|---|---|---|
| 1–10 | The Outer Gate | The Knight-Captain (Floor 10) | Basic hero formations and core defense |
| 11–20 | The Bone Catacombs | The Grave Paladin (Floor 20) | Undead resistance and healing enemies |
| 21–30 | The Blighted Garden | The Thorn Witch (Floor 30) | Poison zones and ranged attackers |
| 31–40 | The Iron Foundry | The Siege Engineer (Floor 40) | Armor and structure damage |
| 41–50 | The Arcane Archive | The Grand Magister (Floor 50) | Magic barriers, teleportation, dispels |
| 51–60 | The Blood Moon Keep | The Crimson Saint (Floor 60) | Lifesteal, healing suppression, burst damage |
| 61–70 | The Dragon Grave | The Ashen Dragon (Floor 70) | Breath attacks and area destruction |
| 71–80 | The Celestial Prison | The Fallen Seraph (Floor 80) | Shielded elite parties and holy damage |
| 81–90 | The Abyssal Rift | The Void Champion (Floor 90) | Unusual movement, summoning, shifting defenses |
| 91–99 | The Throne Approach | The Legendary Hero Party | Coordinated parties combining learned tactics |
| 100 | The Demon Lord's Throne | The Final Invasion | Multi-phase siege on the strongest core |

Regular floors should mix procedural wave configurations with authored encounters. All 100 floors must have valid data, progression links, and completion conditions. Procedural variation must not replace required authored boss mechanics.

## Combat and player abilities

- Automatic core attacks, guardian attacks, turret fire, traps, shields, and summoned minions.
- Player-directed strategic choices: upgrades, unit composition, evolution, relic loadout, and limited-use abilities.
- Suggested active abilities: Meteor Strike, Soul Drain, and Emergency Shield.
- Core destruction ends the current run. Do not erase the entire account or permanent research on defeat.
- Defeating the required enemies completes a floor and unlocks the next.
- Difficulty should increase through enemy combinations and smarter tactics, not merely inflated health values.
- Combat needs a fixed simulation timestep with bounded catch-up processing; rendering may run at a separate rate.

## Original guardian roster (initial targets)

These are planned designs, not existing implemented assets.

1. **Varkhan, Abyss Knight** — frontline guardian; high health, melee attacks, taunt; evolves into Dread Commander.
2. **Nyxara, Soul Weaver** — ranged magic damage; tracking soul bolts and chained damage; evolves into Soul Matriarch.
3. **Morveth, Bone Marksman** — long-range specialist; prioritizes healers and mages, piercing arrows, charged execution shot.
4. **Grum, Rune Golem** — defensive support; absorbs damage, shields nearby structures, ground-slam stun.
5. **Zippi, Chaos Imp** — rapid-fire support; chaotic projectiles, attack-speed bonus against crowds, occasional armor weakening.

Expand the roster with additional original units, variants, and evolutions as production allows. Keep each character data-driven and modular.

## Enemy roster and AI

Initial enemy archetypes:

- **Vanguard:** advances and attacks the first defense encountered; counter with sustained damage.
- **Ranger:** attacks structures from range; counter with priority targeting and mobile/ranged defenders.
- **Battle Mage:** area damage and shield breaking; counter with interrupts and fast elimination.
- **Field Medic:** heals nearby heroes; treat as a high-priority target.
- **Shadow Assassin:** bypasses some frontline defenders; counter with detection, traps, and wards.
- **Siege Golem:** slow, armored, high structure damage; counter with armor penetration and focused damage.
- **Relic Hunter:** gains temporary protection from relics; counter with disables and burst damage.
- **Champion:** elite units with multiple skills; counter with focused damage and layered defenses.

AI requirements: role-based target priorities; stable target selection that avoids trivial retargeting; party coordination; boss skill timing; pathfinding around blockers; alternate routes where supported; difficulty through tactics and composition; and controlled AI update intervals to avoid expensive pathfinding every render frame.

Hero decision flow: spawn and form party → select route and identify threats → move, attack, use skills, or support allies → retarget, recover, advance, or retreat.

## Defensive structures and core evolutions

Structure families:
- **Soul Turret:** rapid single-target magic damage.
- **Rift Trap:** damages and slows enemies crossing its area.
- **Void Ward:** shields the core and nearby structures.
- **Summoning Gate:** periodically deploys temporary demon minions.

Core evolution branches:
- **Infernal Core:** high damage, explosions, burn effects, offensive turret bonuses.
- **Abyssal Core:** shields, damage reduction, defensive regeneration, control effects.
- **Soulbound Core:** soul collection, summon bonuses, lifesteal, long-term resource generation.

Example wave upgrades: split soul bolts; reflect part of incoming damage with shields; guardian attack speed after kills; stacking curse traps; increased boss damage while the core is below half health. Offer three options from an authored pool after selected waves. Weight offers toward the current build without preventing unusual combinations.

## Boss design

Bosses need authored phases, readable telegraphs, and mechanics—not just large health pools.

- **Floor 10, Knight-Captain:** defensive stance, charging strike, shielded soldiers at health thresholds.
- **Floor 30, Thorn Witch:** hazardous ground, root summons, healing while support units survive.
- **Floor 70, Ashen Dragon:** sweeping breath, armored flight phases, add wave pressuring multiple positions.
- **Floor 100, Legendary Hero Party:** warrior pressures frontline, mage breaks shields, healer sustains party, assassin targets critical structures.

Final invasion stages:
1. **Breach attempt:** test defenses and reveal attack strategy.
2. **Coordinated assault:** signature abilities force adaptation.
3. **Last stand:** surviving heroes gain a desperation ability with clear telegraphs and a limited window to stop them.

Winning Floor 100 completes the main campaign and unlocks endless survival with escalating combinations and additional prestige milestones.

## Resources, research, and prestige

| Resource | Source | Use |
|---|---|---|
| Gold | Hero defeats, floor rewards, idle income | Upgrade structures and units |
| Souls | Defeated heroes and bosses | Summon guardians and evolve units |
| Relic fragments | Milestone bosses and challenges | Core evolutions and rare relics |
| Research points | Floor clears and achievements | Permanent research |
| Demon seals | Prestige milestones | Advanced permanent bonuses |

Progression layers:
1. **During a floor:** temporary upgrades, wave rewards, emergency skills.
2. **Between floors:** unit upgrades, relic choices, eligible repairs and defense changes.
3. **Permanent research:** base-stat improvements and mechanic unlocks across runs.
4. **Collection:** units, cosmetics, bestiary entries, evolution forms.
5. **Prestige:** reset clearly identified eligible tower progress for a permanent resource.

Research branches:
- **Core Mastery:** health, shields, regeneration, core attacks.
- **Demonology:** unit damage, summon limits, guardian evolution.
- **Engineering:** turret damage, traps, defensive slots.
- **Soul Alchemy:** resource gain, relic crafting, offline earnings.
- **Lordship:** ultimate abilities, prestige benefits, advanced unlocks.

Research UI must show prerequisites, current rank, next rank, cost, and actual effect. Prestige must preview exactly what resets and what remains, then require confirmation. Permanent progression must not make all earlier choices unusable.

## Original art, animation, and effects

The finished release must integrate original stylized 2D dark-fantasy art. Do not rely on colored squares or unanimated placeholders as the final visual experience.

Required character animations: idle, walk, attack, skill cast, hit reaction, stun, death. Required VFX: projectile trails, impact bursts, runes, shields, explosions, status indicators, and damage numbers. Bosses need attack wind-ups, warning zones, phase transitions, and distinct silhouettes. The core needs idle pulse, damage, shielded, critical-health, breach, and defeat states.

Art pipeline rules:
- Shared palette, outline treatment, lighting direction, and sprite scale.
- Distinct silhouettes readable on small Android screens.
- Reusable 2D rigs where suitable and sprite-sheet animation where appropriate.
- Separate art assets from combat data.
- Pool frequently spawned effects and provide reduced-effects options for older devices.
- Track attribution and license information for third-party fonts, sounds, tools, or libraries.

## Android UI

Use portrait touchscreens by default unless device testing demonstrates a better layout.

Required screens:
- Main menu: Continue, Tower, Research, Guardians, Relics, Settings.
- Battle: combat field, core health, floor/wave, resources, speed, skills, pause.
- Floor results: rewards, performance, next floor, retry.
- Guardian collection: stats, skills, evolution, unlocked skins.
- Research: permanent upgrades and prerequisites.
- Relics: collection, equipped loadout, set bonuses.
- Prestige: reset preview, reward calculation, confirmation.
- Settings: sound, music, vibration, effect quality, text size, save status, offline progress details.

UI must work on narrow Android screens, with readable text, large touch targets, no overlapping popups, and no content hidden behind system navigation.

## Local save and offline earnings

The first release must work fully offline. No account, cloud save, or mandatory sign-in is required.

Persist: highest unlocked floor; current run, wave, core health, and eligible run upgrades; resources; guardian unlocks, levels, evolutions, loadouts; research ranks; relics; achievements; prestige history; settings; schema version; and last session timestamp.

Save requirements: versioned data, migration logic, atomic writes, and recovery from corrupted saves. A failed write must not silently replace valid data with incomplete data.

Offline reward flow:
1. Read the last valid saved timestamp.
2. Calculate elapsed time and bound it by a configurable maximum.
3. Simulate only systems explicitly designed for offline progression, such as idle resource production.
4. Apply resource caps and economy limits.
5. Persist results and display an offline reward summary.

Initial balance target: maximum 8 hours of offline earnings, subject to testing. Combat waves and bosses do not advance while the app is closed in the first release. Use monotonic time during a live session and treat wall-clock changes cautiously. Local-only time checks cannot fully prevent clock manipulation; do not make this economy dependent on competitive or real-money rewards.

Save tests: force-stop/reopen; migrate older schema; interrupt writes; test zero, short, maximum, and excessive offline durations; ensure rewards cannot be claimed twice; ensure floor changes and defeat do not erase permanent research.

## Technical architecture

Recommended engine: Godot 4 + GDScript, subject to verifying the actual project and available Android export setup.

Suggested modular layout:

```text
project.godot
scenes/
  main_menu/
  battle/
  tower_map/
  research/
  guardian_collection/
  results/
systems/
  combat_simulator/
  enemy_ai/
  pathfinding/
  wave_director/
  core_and_defenses/
  upgrades_and_research/
  progression/
  save_manager/
  offline_rewards/
content/
  guardians/
  enemies/
  bosses/
  floors/
  skills/
  relics/
assets/
  characters/
  environments/
  effects/
  ui/
  audio/
tests/
  combat/
  progression/
  save_load/
  android_smoke/
```

Architecture rules:
- Unit stats, skills, waves, and floor definitions must be data resources rather than hardcoded per encounter.
- Reuse controllers, animation state machines, projectiles, damage handlers, and status effects.
- Separate simulation from rendering.
- Use deterministic seeded encounters where practical.
- Use fixed simulation timing with bounded catch-up.
- Pool frequently spawned projectiles and effects.
- Version save data and provide migrations.
- Document Android export and signing setup. Never commit private signing keys or secrets.

## Definition of done

- [ ] Install, launch, play, save, close, and resume work.
- [ ] Core automatically attacks and can be destroyed by heroes.
- [ ] Hero AI, guardians, skills, status effects, and bosses work correctly.
- [ ] Original character artwork and animations are integrated into gameplay.
- [ ] All 100 floors have tested progression and completion conditions.
- [ ] Research, evolutions, rewards, and prestige persist.
- [ ] Offline earnings are bounded, correctly calculated, and cannot be claimed twice.
- [ ] Performance is acceptable on target Android hardware.
- [ ] Final APK is retrievable, valid, installable, and smoke-tested.
- [ ] Repository includes setup/build instructions and known limitations.

## Current status and honesty policy

This README is the design target, not evidence that the game is implemented. Track completed features in the roadmap with links to commits, tests, workflow runs, and artifacts. Never claim that source code was changed, CI passed, an APK exists, or device testing succeeded unless that evidence has actually been observed.

## Mandatory AI and contributor instructions

Before changing code, read [AGENTS.md](AGENTS.md), [AI guidelines](.github/copilot-instructions.md), [the full game design](docs/GAME_DESIGN.md), and [the roadmap](docs/ROADMAP.md). Treat those documents as the canonical project requirements. Update the roadmap only after verifiable work; do not silently downgrade the intended scope.
