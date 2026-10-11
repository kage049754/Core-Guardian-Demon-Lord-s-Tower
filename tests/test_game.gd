extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	if scene == null:
		push_error("main scene could not be loaded")
		quit(1)
		return
	var game: Variant = scene.instantiate()
	root.add_child(game)
	if game.floor_number != 1 or game.core_hp <= 0.0:
		push_error("new run did not initialize correctly")
		quit(1)
		return
	game.floor_number = 10
	game._spawn_enemy()
	if game.enemies.size() != 1 or not game.enemies[0]["boss"]:
		push_error("floor 10 boss spawn failed")
		quit(1)
		return
	game.enemies.clear()
	game.shield = 20.0
	var hp: float = game.core_hp
	game._damage_core(10.0)
	if game.shield != 10.0 or game.core_hp != hp:
		push_error("shield absorption failed")
		quit(1)
		return
	game.shield = 0.0
	game.core_hp = 1.0
	game._damage_core(5.0)
	if not game.lost or game.core_hp != 0.0:
		push_error("core defeat transition failed")
		quit(1)
		return
	print("PASS: startup, boss spawn, shield absorption, and core defeat")
	quit(0)
