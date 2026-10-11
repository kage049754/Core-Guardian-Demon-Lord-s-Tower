# Core Guardian test plan

## Current scope
These checks are acceptance criteria for the first playable vertical slice. They are not evidence that all tests have already been run.

## Combat
- Core attack reduces the selected target's HP and creates a visual-only attack streak.
- Guardian attacks apply damage in the simulation.
- Enemy HP reaching zero grants one reward and removes the enemy.
- Enemies entering core range damage the core, with shield absorption applied first.
- Core HP reaching zero triggers defeat exactly once.
- Bosses spawn on milestone floors and have increased HP/damage.
- Wave completion occurs only after the configured enemies are spawned and defeated.
- The player must not advance a floor while enemies remain.

## Progression
- Upgrade costs are deducted once and stats increase.
- Insufficient resources do not change stats.
- Research levels persist after defeat and reload.
- Floor 100 victory unlocks endless survival.
- A defeat retry preserves permanent research.

## Save and offline rewards
- Force-stop/reopen restores progression.
- Invalid JSON and unsupported schema versions do not crash startup.
- Offline time is clamped to 8 hours and negative elapsed time yields no reward.
- Offline reward is granted once per saved interval.
- Temporary files are used when writing save data.
- Test interrupted writes and verify a previous valid save is recoverable.

## Android release
- CI parser/import checks pass.
- APK artifact exists and package metadata is readable.
- Install and launch on an Android device.
- Exercise combat, upgrades, core defeat, retry, save/load, and offline reward.
- Report CI, APK integrity, installation, launch, and gameplay separately.
