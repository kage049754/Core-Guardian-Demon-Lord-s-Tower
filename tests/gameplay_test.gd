extends SceneTree

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	if packed == null:
		_fail("Main battle scene could not be loaded.")
		return
	var game: Variant = packed.instantiate()
	root.add_child(game)
	await process_frame
	game._new_game()
	if game.floor_number != 1 or game.core_hp <= 0:
		_fail("New-game initialization failed.")
		return

	game.floor_number = 10
	game._start_wave()
	game._spawn_enemy()
	if game.enemies.size() != 1 or not bool(game.enemies[0].get("boss", false)):
		_fail("Floor 10 milestone boss did not spawn.")
		return

	var boss_probe: Dictionary = {"name": "Boss Probe", "hp": 50.0, "max_hp": 100.0, "damage": 10.0, "distance": 200.0}
	game.floor_number = 20
	boss_probe = game._apply_boss_special(boss_probe)
	if float(boss_probe["hp"]) != 58.0:
		_fail("Grave Paladin did not restore its armor.")
		return
	game.floor_number = 50
	game.shield = 30.0
	game._apply_boss_special(boss_probe)
	if game.shield != 5.0:
		_fail("Grand Magister did not dispel core shield.")
		return
	game.floor_number = 90
	boss_probe["distance"] = 200.0
	boss_probe = game._apply_boss_special(boss_probe)
	if float(boss_probe["distance"]) != 265.0:
		_fail("Void Champion did not displace itself.")
		return
	game.floor_number = 100
	game.core_hp = 100.0
	game.shield = 0.0
	game.core_evolution = "infernal"
	game.lost = false
	game.floor_cleared = false
	game.campaign_won = false
	game.enemies.clear()
	game.enemies.append(boss_probe.duplicate())
	game.enemies.append(boss_probe.duplicate())
	game._apply_boss_special(boss_probe)
	if game.core_hp >= 100.0:
		_fail("Legendary Hero Party did not coordinate its attack.")
		return

	var phase_probe: Dictionary = {"name": "Phase Test", "hp": 50.0, "max_hp": 100.0, "speed": 10.0, "damage": 10.0, "phase": 1}
	phase_probe = game._update_boss_phase(phase_probe)
	if int(phase_probe["phase"]) != 2 or float(phase_probe["speed"]) <= 10.0:
		_fail("Boss did not enter Phase II at half health.")
		return
	phase_probe["hp"] = 25.0
	var phase_two_speed: float = float(phase_probe["speed"])
	phase_probe = game._update_boss_phase(phase_probe)
	if int(phase_probe["phase"]) != 3 or float(phase_probe["speed"]) <= phase_two_speed:
		_fail("Boss did not enter its final phase at low health.")
		return

	game.enemies.clear()
	game.floor_number = 1
	game._start_wave()
	game._spawn_enemy()
	var initial_enemy_hp: float = float(game.enemies[0]["hp"])
	game._turret_attack()
	if float(game.enemies[0]["hp"]) >= initial_enemy_hp:
		_fail("Soul Turret did not damage its target.")
		return

	game.shield = 20.0
	var initial_core_hp: float = game.core_hp
	game._damage_core(10.0)
	if game.shield != 10.0 or game.core_hp != initial_core_hp:
		_fail("Shield did not absorb incoming damage first.")
		return

	game.core_hp = 1.0
	game.shield = 0.0
	game._damage_core(5.0)
	if not game.lost or game.core_hp != 0.0:
		_fail("Core destruction did not trigger defeat.")
		return
	if not is_instance_valid(game.results_overlay):
		_fail("Core destruction did not show the defeat results screen.")
		return

	game.lost = false
	game.gold = 1000
	game.research_points = 1
	game.research_selector.select(0)
	var previous_damage: float = game.core_damage
	game._buy_research()
	if int(game.research_ranks.get("core_mastery", 0)) != 1 or game.core_damage <= previous_damage:
		_fail("Core Mastery research did not apply its permanent effect.")
		return

	game.research_points = 3
	game._evolve_core()
	if game.core_evolution != "abyssal":
		_fail("Core evolution cycle failed.")
		return

	# Verify persisted progress restores, and offline earnings cannot be claimed twice.
	game.floor_number = 6
	game.gold = 321
	game._save_game()
	game.floor_number = 2
	game.gold = 0
	game._load_game()
	if game.floor_number != 6 or game.gold < 321:
		_fail("Local save did not restore floor and gold.")
		return

	var main_save_path := ProjectSettings.globalize_path("user://core_guardian_save.json")
	var backup_save_path := ProjectSettings.globalize_path("user://core_guardian_save.json.bak")
	if FileAccess.file_exists(backup_save_path):
		DirAccess.remove_absolute(backup_save_path)
	var backup_move_error := DirAccess.rename_absolute(main_save_path, backup_save_path)
	if backup_move_error != OK:
		_fail("Could not prepare backup recovery test.")
		return
	game.gold = 0
	game._load_game()
	if game.gold < 321 or not FileAccess.file_exists("user://core_guardian_save.json"):
		_fail("Missing primary save did not recover from backup.")
		return

	var save_file := FileAccess.open("user://core_guardian_save.json", FileAccess.READ)
	if save_file == null:
		_fail("Save file was not created.")
		return
	var parsed_save: Variant = JSON.parse_string(save_file.get_as_text())
	save_file.close()
	if typeof(parsed_save) != TYPE_DICTIONARY:
		_fail("Save JSON could not be parsed.")
		return
	var save_data: Dictionary = parsed_save
	save_data["last_saved_unix"] = int(Time.get_unix_time_from_system()) - 120
	var aged_file := FileAccess.open("user://core_guardian_save.json", FileAccess.WRITE)
	if aged_file == null:
		_fail("Could not prepare offline reward boundary test.")
		return
	aged_file.store_string(JSON.stringify(save_data))
	aged_file.close()
	var gold_before_offline: int = int(game.gold)
	game._load_game()
	if game.gold < gold_before_offline + 2:
		_fail("Two-minute offline reward was not credited.")
		return
	var gold_after_claim: int = int(game.gold)
	game._load_game()
	if game.gold != gold_after_claim:
		_fail("Offline reward was claimable more than once.")
		return

	game.unlocked_relics = ["shard_of_the_first_demon", "healer_bane", "broken_halo", "dragon_heart"]
	game.equipped_relics.clear()
	game._toggle_relic("shard_of_the_first_demon")
	game._toggle_relic("healer_bane")
	game._toggle_relic("broken_halo")
	game._toggle_relic("dragon_heart")
	if game.equipped_relics.size() != 3 or not game._has_relic("shard_of_the_first_demon") or game._has_relic("dragon_heart"):
		_fail("Three-slot relic loadout limit or equipped bonuses failed.")
		return

	game.defeated = 1
	game.unlocked_achievements.clear()
	game._check_achievements()
	if not game.unlocked_achievements.has("first_blood"):
		_fail("First Blood achievement did not unlock.")
		return
	game._save_game()
	game.unlocked_achievements.clear()
	game._load_game()
	if not game.unlocked_achievements.has("first_blood"):
		_fail("Achievement progress did not persist to the local save.")
		return

	game.highest_floor_unlocked = 3
	game._select_floor(2)
	if game.floor_number != 2 or game.highest_floor_unlocked != 3:
		_fail("Tower map replay did not preserve the highest unlocked floor.")
		return
	game._select_floor(1)
	if game.floor_number != 1 or game.highest_floor_unlocked != 3:
		_fail("Replaying an earlier floor reduced campaign unlock progress.")
		return

	game.floor_number = 100
	game.highest_floor_unlocked = 100
	game.floor_cleared = true
	game.campaign_won = false
	game.endless_mode = false
	game._next_floor()
	if not game.campaign_won:
		_fail("Clearing floor 100 did not complete the campaign.")
		return
	game._next_floor()
	if game.floor_number != 101 or not game.endless_mode or game.campaign_won:
		_fail("Campaign completion did not unlock Endless Spire.")
		return

	game._new_game()
	if not game.equipped_relics.is_empty() or not game.unlocked_relics.is_empty():
		_fail("Fresh game retained relics from the previous save.")
		return
	print("PASS: combat, boss mechanics, research, evolution, save/load, offline rewards, relic loadouts, achievements, and fresh-save reset.")
	quit(0)

func _fail(reason: String) -> void:
	push_error("GAMEPLAY TEST FAILED: " + reason)
	quit(1)
