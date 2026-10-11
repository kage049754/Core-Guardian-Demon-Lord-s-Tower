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
	var gold_before_offline := game.gold
	game._load_game()
	if game.gold < gold_before_offline + 2:
		_fail("Two-minute offline reward was not credited.")
		return
	var gold_after_claim := game.gold
	game._load_game()
	if game.gold != gold_after_claim:
		_fail("Offline reward was claimable more than once.")
		return

	game._new_game()
	print("PASS: startup, boss spawn, turret damage, shield absorption, defeat, research, evolution, save/load, and single-claim offline rewards.")
	quit(0)

func _fail(reason: String) -> void:
	push_error("GAMEPLAY TEST FAILED: " + reason)
	quit(1)
