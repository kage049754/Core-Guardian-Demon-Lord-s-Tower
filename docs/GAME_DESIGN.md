# Game design specification

This is the detailed canonical design for **Core Guardian: Demon Lord's Tower**. AI agents and contributors must read this document before implementation. The root README is a summary; this document expands the required mechanics and production direction.

## 1. Vision and story

A 100-floor offline-first Android idle tower-defense game in original stylized 2D dark fantasy. The player is the Demon Lord, owner of a tower containing treasure, forbidden magic, and guardians. Heroes climb the tower to steal the treasure and kill the Demon Lord. The heroes must destroy the Demonic Core before reaching the throne. The player protects the core using automatic attacks, guardians, turrets, traps, shields, summons, upgrades, and active skills.

The game should feel like ruling and fortifying a dungeon, not controlling a conventional hero party. A failed floor ends the current run but does not erase permanent progression.

## 2. Gameplay loop and rules

1. Heroes enter through designated points and arrive in waves.
2. Core and defensive systems attack automatically.
3. Hero AI moves, selects targets, attacks, supports allies, and uses skills.
4. The player chooses upgrades and can activate limited-use abilities.
5. Enemies drop resources and bosses grant special rewards.
6. Clear required encounters to unlock the next floor.
7. Use between-floor upgrades and permanent research to improve the tower.
8. Core destruction breaches the floor and ends the run.
9. Campaign completion unlocks endless survival and further prestige.

Combat truth belongs to a deterministic or reproducibly seeded simulation layer. Animation and VFX must display the simulation; they must not secretly decide damage, death, or wave completion.

## 3. Campaign map

Ten regions, each with a distinct background palette, props, enemy pool, and boss:

1. Floors 1–10: The Outer Gate; Floor 10 Knight-Captain; basic defense.
2. Floors 11–20: The Bone Catacombs; Floor 20 Grave Paladin; undead resistance and healing.
3. Floors 21–30: The Blighted Garden; Floor 30 Thorn Witch; poison and ranged attackers.
4. Floors 31–40: The Iron Foundry; Floor 40 Siege Engineer; armor and structure damage.
5. Floors 41–50: The Arcane Archive; Floor 50 Grand Magister; barriers, teleportation, dispels.
6. Floors 51–60: The Blood Moon Keep; Floor 60 Crimson Saint; lifesteal and healing suppression.
7. Floors 61–70: The Dragon Grave; Floor 70 Ashen Dragon; breath and area destruction.
8. Floors 71–80: The Celestial Prison; Floor 80 Fallen Seraph; shields and holy damage.
9. Floors 81–90: The Abyssal Rift; Floor 90 Void Champion; shifting defenses and summoning.
10. Floors 91–99: The Throne Approach; Legendary Hero Party; combined tactics.
11. Floor 100: The Demon Lord's Throne; Final Invasion.

Floor 100 is the final campaign encounter. It should contain a breach attempt, a coordinated assault, and a last-stand phase. Winning unlocks endless survival. All floors need valid definitions, entry conditions, rewards, and links; use data-driven authored encounters and controlled wave variation.

## 4. Original guardians

Initial planned units:
- **Varkhan, Abyss Knight:** high-health melee frontline, taunt, evolves into Dread Commander.
- **Nyxara, Soul Weaver:** tracking soul bolts and chain damage, evolves into Soul Matriarch.
- **Morveth, Bone Marksman:** long range, targets healers/mages, piercing arrows and charged execution.
- **Grum, Rune Golem:** damage absorption, structure shields, ground-slam stun.
- **Zippi, Chaos Imp:** fast projectiles, attack speed against crowds, occasional armor weakening.

These are design targets, not implemented assets. Expand as production capacity allows. Each unit requires portrait, world sprite/rig, animation states, stats, skills, effects, sound, unlock source, and evolution path.

## 5. Enemies and hero AI

Initial archetypes:
- Vanguard: advances and attacks the first defense.
- Ranger: ranged structure damage.
- Battle Mage: area damage and shield breaking.
- Field Medic: heals nearby heroes.
- Shadow Assassin: bypasses some frontline defenders.
- Siege Golem: slow armored structure breaker.
- Relic Hunter: temporary protection from relics.
- Champion: elite with multiple skills.

AI design:
- Target priorities depend on role, threats, range, and available path.
- Target selection must be stable and avoid needless switching.
- Parties coordinate: warriors engage frontline, ranged units remain behind, healers support.
- Bosses telegraph skills and avoid wasting attacks on invulnerable targets.
- Pathfinding handles blockers and supported alternate routes.
- Difficulty comes from composition, timing, and tactics, not only health multipliers.
- AI decisions run on controlled intervals; do not perform expensive pathfinding on every rendered frame.

Decision loop: spawn/form party → choose route/identify threats → move/attack/skill/support → retarget/recover/advance/retreat.

## 6. Defenses and abilities

Structures:
- Soul Turret: fast single-target magic.
- Rift Trap: area damage and slow.
- Void Ward: shields core and nearby structures.
- Summoning Gate: periodic temporary demon minions.

Core branches:
- Infernal: offensive damage, explosions, burn, turret bonuses.
- Abyssal: shields, mitigation, regeneration, control.
- Soulbound: soul income, summon bonuses, lifesteal, resource generation.

Active ability examples: Meteor Strike, Soul Drain, Emergency Shield. Ability cooldowns, costs, targets, and effects must be visible and implemented. No button may be decorative or inert.

Upgrade choice examples: split soul bolts; reflect damage with shields; guardians gain attack speed after kills; traps apply stacking curses; bonus boss damage when core health is low. Present three options from an authored pool after selected waves. Weight by build while allowing unusual combinations.

## 7. Boss encounters

- Knight-Captain: defense stance, charge attack, shielded soldiers.
- Grave Paladin: healing/undead-themed boss.
- Thorn Witch: hazard zones, root summons, heals while support survives.
- Siege Engineer: armor and structure-targeting siege mechanics.
- Grand Magister: barriers, teleportation, dispels.
- Crimson Saint: lifesteal and healing suppression.
- Ashen Dragon: sweeping breath, armored flight, additional enemies.
- Fallen Seraph: elite shielded parties and holy damage.
- Void Champion: shifting arena/defense behavior and summons.
- Legendary Hero Party: coordinated warrior, mage, healer, and assassin.

Every boss requires authored phases, telegraphed attacks, clear counterplay, transition logic, rewards, and tests. A boss is not complete just because it has increased health and damage.

## 8. Art and animation direction

Use original stylized 2D dark-fantasy artwork with consistent scale, outlines, palette, and lighting. Silhouettes must remain readable on small mobile screens. Use 2D skeletal rigs where appropriate and frame-based sprite sheets where appropriate.

Required animation states: idle, walk, attack, cast, hit, stun, death. Required VFX: projectile trails, impacts, runes, shields, explosions, damage numbers, status effects, boss telegraphs, and phase transitions. Core states: idle pulse, damaged, shielded, critical, breached, defeated.

Asset rules:
- Keep visuals separate from combat data.
- Use reusable controllers and effect systems.
- Pool frequent effects.
- Provide reduced-effects options.
- Record license and attribution for third-party assets.
- Do not represent placeholders as completed production art.

## 9. Progression and economy

Resources:
- Gold: unit and structure upgrades; hero defeats, floor rewards, idle income.
- Souls: summon and evolve guardians; hero and boss defeats.
- Relic fragments: core evolutions and rare relics; bosses/challenges.
- Research points: permanent research; floors/achievements.
- Demon seals: advanced permanent bonuses; prestige milestones.

Layers: run upgrades; between-floor upgrades; permanent research; unit/relic/bestiary collection; prestige.

Research branches:
- Core Mastery: health, shields, regeneration, core attacks.
- Demonology: unit damage, summon limits, evolutions.
- Engineering: turret damage, traps, defensive slots.
- Soul Alchemy: resource gain, relic crafting, offline income.
- Lordship: ultimate abilities, prestige, advanced unlocks.

Research nodes show prerequisites, current/next rank, cost, and actual effects. Prestige must preview exactly what resets and what remains and require confirmation. Balance should encourage experimentation rather than make previous choices useless.

## 10. Save system and offline rewards

Fully offline initial release. No mandatory account, cloud save, or online dependency.

Persist campaign floor, current run state, wave/core health, run upgrades, resources, guardian collection/levels/evolutions/loadouts, research, relics, achievements, prestige, settings, schema version, and last session timestamp.

Implement versioned save data, migrations, atomic writes, and corruption recovery. Never overwrite a valid save with a partial failed write.

Offline calculation:
- Read last valid timestamp.
- Calculate elapsed time and cap it.
- Progress only approved idle resource systems.
- Apply caps and economy limits.
- Save result and display a summary.
- Initial cap target is 8 hours, to be tuned after tests.
- Combat and boss waves do not advance offline in release 1.
- Use monotonic time for live sessions; treat wall-clock changes cautiously.
- Prevent duplicate claims. Local-only checks cannot fully prevent clock manipulation; never rely on this for competitive or real-money rewards.

Tests include force-stop/reopen, schema migration, interrupted save, zero/short/capped/excessive elapsed time, duplicate claims, and preservation of permanent progress after defeat.

## 11. Android UI

Portrait by default unless testing supports another layout. Screens: main menu, battle, floor results, tower map, guardian collection, research, relics, prestige, settings. Settings include audio, vibration, effect quality, text size, save status, and offline-reward details. Use readable text, large touch targets, and no content hidden behind system navigation.

Battle HUD includes core health, floor/wave, resources, speed control, active skills, pause, and upgrades. The tower map shows the 100-floor progression, region milestones, bosses, and replayable floors.

## 12. Architecture and quality

Recommended engine is Godot 4/GDScript, subject to inspection of the real repository. Suggested modules: scenes for menu/battle/map/research/collection/results; systems for combat simulation, AI, pathfinding, waves, core/defenses, upgrades, progression, saves, and offline rewards; data resources for guardians, enemies, bosses, floors, skills, and relics; assets for characters, environments, effects, UI, and audio; tests for combat, progression, saves, and Android smoke.

Use data-driven definitions, simulation/render separation, seeded encounters where practical, fixed simulation timing, bounded catch-up, pooled projectiles/effects, save migrations, and documented Android export/signing. Never commit signing keys or secrets.

## 13. Release definition

Release is done only when:
- APK installs, launches, plays, saves, closes, and resumes.
- Core attacks and can be destroyed.
- AI, guardians, skills, status effects, and boss phases work.
- Original art and animation are integrated.
- All 100 floors and progression links are tested.
- Research/evolutions/rewards/prestige persist.
- Offline rewards are bounded and cannot be duplicated.
- Performance is acceptable on target devices.
- Final APK artifact is retrieved, validated, install-tested, and smoke-tested.
- Build/setup instructions and known limitations are documented.

Always distinguish CI success, artifact existence/integrity, installation, launch, and actual gameplay tests. A pending run or green workflow alone is not proof of a working game.
