extends Node2D
## First playable slice: automatic 360-degree core defense, touch upgrades,
## 100-floor progression, milestone bosses, local saves and capped offline gold.
## All combat outcomes are simulated here; _draw() only visualizes game state.

const SAVE_PATH := "user://core_guardian_save.json"
const MAX_OFFLINE_SECONDS := 8 * 60 * 60
const FLOOR_COUNT := 100
const REGION_NAMES := [
	"The Outer Gate", "The Bone Catacombs", "The Blighted Garden",
	"The Iron Foundry", "The Arcane Archive", "The Blood Moon Keep",
	"The Dragon Grave", "The Celestial Prison", "The Abyssal Rift",
	"The Throne Approach"
]
const ENEMY_NAMES := ["Vanguard", "Ranger", "Battle Mage", "Field Medic", "Shadow Assassin", "Siege Golem", "Relic Hunter", "Champion"]
const GUARDIAN_NAMES := ["Varkhan · Abyss Knight", "Nyxara · Soul Weaver", "Morveth · Bone Marksman", "Grum · Rune Golem", "Zippi · Chaos Imp"]

var rng := RandomNumberGenerator.new()
var floor_definitions: Array = []
var enemies: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var floor_number := 1
var wave_number := 1
var wave_limit := 5
var core_hp := 100.0
var core_max_hp := 100.0
var gold := 0
var souls := 0
var research_points := 0
var core_damage := 12.0
var attack_rate := 0.8
var shield := 0.0
var research_level := 0
var guardian_level := 1
var defeated := 0
var wave_spawned := 0
var spawn_clock := 0.0
var attack_clock := 0.0
var game_clock := 0.0
var lost := false
var floor_cleared := false
var campaign_won := false
var message := "The heroes are coming. Protect the core."
var message_clock := 5.0
var selected_panel := "battle"
var offline_summary := ""
var last_saved_unix := 0
var skill_cooldown := 0.0
var skill_ready := true
var screen_size := Vector2(720, 1280)
var ui_layer: CanvasLayer
var hud_label: Label
var status_label: Label
var buttons: Array[Button] = []

func _ready() -> void:
	rng.randomize()
	screen_size = get_viewport_rect().size
	_load_floor_content()
	_build_ui()
	_load_game()
	_start_wave()
	queue_redraw()

func _process(delta: float) -> void:
	if message_clock > 0.0:
		message_clock -= delta
	if skill_cooldown > 0.0:
		skill_cooldown = maxf(0.0, skill_cooldown - delta)
		skill_ready = skill_cooldown <= 0.0
	if not lost and not campaign_won:
		game_clock += delta
		_update_combat(delta)
		_update_ui()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_game()

func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(root)
	var title := Label.new()
	title.text = "CORE GUARDIAN  ·  DEMON LORD'S TOWER"
	title.position = Vector2(22, 18)
	title.size = Vector2(676, 44)
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color(0.95, 0.77, 0.48))
	root.add_child(title)
	hud_label = Label.new()
	hud_label.position = Vector2(22, 66)
	hud_label.size = Vector2(676, 90)
	hud_label.add_theme_font_size_override("font_size", 20)
	hud_label.add_theme_color_override("font_color", Color(0.92, 0.9, 1.0))
	root.add_child(hud_label)
	status_label = Label.new()
	status_label.position = Vector2(22, 158)
	status_label.size = Vector2(676, 48)
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color(0.74, 0.84, 0.91))
	root.add_child(status_label)
	var y := 1030.0
	_add_button(root, "UPGRADE CORE  ·  %s gold" % _upgrade_cost(), Rect2(22, y, 328, 72), _upgrade_core)
	_add_button(root, "SUMMON GUARDIAN  ·  %s souls" % _summon_cost(), Rect2(366, y, 332, 72), _summon_guardian)
	_add_button(root, "EMERGENCY SHIELD", Rect2(22, y + 82, 328, 72), _cast_shield)
	_add_button(root, "RESEARCH  ·  %s gold" % _research_cost(), Rect2(366, y + 82, 332, 72), _buy_research)
	_add_button(root, "NEXT FLOOR / RETRY", Rect2(22, y + 164, 676, 60), _next_floor)
	_add_button(root, "SAVE GAME", Rect2(22, y + 234, 328, 52), _save_game)
	_add_button(root, "RESET SAVE", Rect2(366, y + 234, 332, 52), _reset_save)
	_update_ui()

func _add_button(parent: Control, text_value: String, rect: Rect2, action: Callable) -> void:
	var button := Button.new()
	button.text = text_value
	button.position = rect.position
	button.size = rect.size
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color(0.97, 0.94, 1.0))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.19, 0.10, 0.29)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.34, 0.15, 0.40)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.45, 0.22, 0.34)))
	button.pressed.connect(action)
	parent.add_child(button)
	buttons.append(button)

func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.68, 0.43, 0.83)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 8
	style.content_margin_right = 8
	return style


func _load_floor_content() -> void:
	var file := FileAccess.open("res://content/floors.json", FileAccess.READ)
	if file == null:
		push_warning("Floor content file is missing; using fallback floor scaling.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Floor content data is invalid; using fallback floor scaling.")
		return
	var data: Dictionary = parsed
	var floors: Variant = data.get("floors", [])
	if typeof(floors) == TYPE_ARRAY and floors.size() == FLOOR_COUNT:
		floor_definitions = floors
	else:
		push_warning("Expected 100 floor definitions; using fallback floor scaling.")

func _floor_definition() -> Dictionary:
	var index := clampi(floor_number - 1, 0, floor_definitions.size() - 1)
	if floor_definitions.is_empty():
		return {}
	var value: Variant = floor_definitions[index]
	return value if typeof(value) == TYPE_DICTIONARY else {}

func _update_ui() -> void:
	if not is_instance_valid(hud_label):
		return
	var region: String = str(_floor_definition().get("region", REGION_NAMES[mini(9, int((floor_number - 1) / 10))]))
	hud_label.text = "FLOOR %03d / 100  ·  WAVE %d/%d\nCORE  %.0f/%.0f   ·   SHIELD %.0f\nGOLD %d   SOULS %d   RESEARCH %d" % [floor_number, wave_number, wave_limit, maxf(0, core_hp), core_max_hp, shield, gold, souls, research_points]
	status_label.text = "%s  |  Guardians Lv.%d  |  %s" % [region, guardian_level, message if message_clock > 0 else "Automatic defenses active."]
	if lost:
		status_label.text = "CORE BREACHED — the heroes stopped this run. Permanent research is retained."
	elif floor_cleared:
		status_label.text = "FLOOR CLEARED — upgrade your defenses, then advance."
	elif campaign_won:
		status_label.text = "CAMPAIGN CLEARED — endless survival unlocked. Tap NEXT FLOOR to continue."
	for button in buttons:
		if not is_instance_valid(button):
			continue
		match button.text.split("  ·")[0]:
			"UPGRADE CORE":
				button.text = "UPGRADE CORE  ·  %d gold" % _upgrade_cost()
				button.disabled = gold < _upgrade_cost() or lost or campaign_won
			"SUMMON GUARDIAN":
				button.text = "SUMMON GUARDIAN  ·  %d souls" % _summon_cost()
				button.disabled = souls < _summon_cost() or lost or campaign_won
			"RESEARCH":
				button.text = "RESEARCH  ·  %d gold" % _research_cost()
				button.disabled = gold < _research_cost()
			"EMERGENCY SHIELD":
				button.text = "EMERGENCY SHIELD  ·  %s" % ("READY" if skill_ready else "%.1fs" % skill_cooldown)
				button.disabled = not skill_ready or lost or campaign_won

func _upgrade_cost() -> int:
	return 25 + int(core_damage * 2.0) + floor_number * 3

func _summon_cost() -> int:
	return 4 + guardian_level * 2

func _research_cost() -> int:
	return 40 + research_level * 30

func _start_wave() -> void:
	enemies.clear()
	shots.clear()
	wave_spawned = 0
	spawn_clock = 0.0
	attack_clock = 0.0
	wave_limit = 5 + int((floor_number - 1) / 5)
	if floor_number % 10 == 0:
		wave_limit = 1
	message = "Floor %d invasion begins." % floor_number
	message_clock = 3.0

func _update_combat(delta: float) -> void:
	spawn_clock += delta
	attack_clock += delta
	if wave_spawned < wave_limit and spawn_clock >= maxf(0.35, 1.5 - floor_number * 0.006):
		spawn_clock = 0.0
		_spawn_enemy()
	if attack_clock >= maxf(0.18, 1.0 / (attack_rate + research_level * 0.025)):
		attack_clock = 0.0
		_core_attack()
		_guardian_attack()
	for i in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[i]
		enemy["angle"] = float(enemy["angle"]) + float(enemy["turn"]) * delta
		var distance := float(enemy["distance"]) - float(enemy["speed"]) * delta
		enemy["distance"] = distance
		enemy["attack_clock"] = float(enemy["attack_clock"]) + delta
		if distance <= 100.0:
			_damage_core(float(enemy["damage"]) * delta)
			if lost:
				return
		if float(enemy["hp"]) <= 0.0:
			_on_enemy_defeated(enemy)
			enemies.remove_at(i)
		elif distance <= 92.0:
			_on_core_breached()
			return
		else:
			enemies[i] = enemy
	for i in range(shots.size() - 1, -1, -1):
		var shot: Dictionary = shots[i]
		shot["life"] = float(shot["life"]) - delta
		if float(shot["life"]) <= 0:
			shots.remove_at(i)
		else:
			shots[i] = shot
	if wave_spawned >= wave_limit and enemies.is_empty():
		_complete_wave()

func _spawn_enemy() -> void:
	var boss := bool(_floor_definition().get("boss_floor", floor_number % 10 == 0))
	var kind := 7 if boss else rng.randi_range(0, mini(7, int(floor_number / 12) + 2))
	var scale := 1.0 + floor_number * 0.105
	var hp := (75.0 + floor_number * 13.0) * scale
	var speed := 17.0 + minf(12.0, floor_number * 0.08)
	var damage := 5.0 + floor_number * 0.6
	if boss:
		hp *= 9.0
		speed *= 0.68
		damage *= 3.2
	var angle := rng.randf_range(0.0, TAU)
	var enemy := {
		"kind": kind,
		"name": str(_floor_definition().get("boss_name", "Floor %d Boss" % floor_number)) if boss else ENEMY_NAMES[kind],
		"angle": angle,
		"distance": 410.0,
		"hp": hp,
		"max_hp": hp,
		"speed": speed,
		"damage": damage,
		"turn": rng.randf_range(-0.12, 0.12),
		"attack_clock": 0.0,
		"boss": boss
	}
	enemies.append(enemy)
	wave_spawned += 1

func _core_attack() -> void:
	if enemies.is_empty():
		return
	var target_index := 0
	var best_distance := INF
	for i in range(enemies.size()):
		var d: float = enemies[i]["distance"]
		if d < best_distance:
			best_distance = d
			target_index = i
	var target: Dictionary = enemies[target_index]
	target["hp"] = float(target["hp"]) - (core_damage + research_level * 2.5)
	enemies[target_index] = target
	shots.append({"angle": float(target["angle"]), "distance": float(target["distance"]), "life": 0.16, "color": Color(0.65, 0.35, 1.0)})

func _guardian_attack() -> void:
	if enemies.is_empty() or guardian_level <= 0:
		return
	var count := mini(guardian_level, 3)
	for n in range(count):
		if enemies.is_empty():
			break
		var index := rng.randi_range(0, enemies.size() - 1)
		var enemy: Dictionary = enemies[index]
		enemy["hp"] = float(enemy["hp"]) - 5.0 * guardian_level
		enemies[index] = enemy
		shots.append({"angle": float(enemy["angle"]), "distance": float(enemy["distance"]), "life": 0.13, "color": Color(0.2, 0.92, 0.78)})

func _damage_core(amount: float) -> void:
	var absorbed := minf(shield, amount)
	shield -= absorbed
	core_hp -= amount - absorbed
	if core_hp <= 0:
		core_hp = 0
		_on_core_breached()

func _on_core_breached() -> void:
	if lost or campaign_won:
		return
	floor_cleared = false
	lost = true
	message = "The Demonic Core has been destroyed."
	message_clock = 999.0
	_save_game()

func _on_enemy_defeated(enemy: Dictionary) -> void:
	defeated += 1
	gold += 8 + floor_number * 2 + (25 if enemy["boss"] else 0)
	souls += 1 + (5 if enemy["boss"] else 0)
	if defeated % 5 == 0:
		research_points += 1
	message = "%s defeated. The tower claims its reward." % enemy["name"]
	message_clock = 2.0

func _complete_wave() -> void:
	gold += 15 + floor_number * 3
	if floor_number % 10 == 0:
		research_points += 3
		souls += 8
		message = "Milestone boss defeated. Floor %d cleared." % floor_number
		message_clock = 5.0
	else:
		message = "Wave cleared. Upgrade your defenses or continue."
		message_clock = 3.0
	wave_number += 1
	# The player explicitly advances using NEXT FLOOR. Avoid surprise wave jumps.
	floor_cleared = true
	lost = false
	campaign_won = false
	_save_game()

func _upgrade_core() -> void:
	var cost := _upgrade_cost()
	if gold < cost or (lost and not campaign_won):
		return
	gold -= cost
	core_damage += 4.0 + floor_number * 0.08
	core_max_hp += 15.0
	core_hp = minf(core_max_hp, core_hp + 35.0)
	message = "Core attack and integrity upgraded."
	message_clock = 2.0

func _summon_guardian() -> void:
	var cost := _summon_cost()
	if souls < cost or (lost and not campaign_won):
		return
	souls -= cost
	guardian_level += 1
	message = "%s strengthened to level %d." % [GUARDIAN_NAMES[(guardian_level - 1) % GUARDIAN_NAMES.size()], guardian_level]
	message_clock = 2.5

func _cast_shield() -> void:
	if not skill_ready or lost or campaign_won:
		return
	shield += 35.0 + research_level * 5.0
	skill_ready = false
	skill_cooldown = 20.0
	message = "Emergency Shield absorbed incoming damage."
	message_clock = 2.0

func _buy_research() -> void:
	var cost := _research_cost()
	if gold < cost:
		return
	gold -= cost
	research_level += 1
	research_points += 1
	message = "Permanent research improved. Its combat bonus persists after defeat."
	message_clock = 2.5
	_save_game()

func _next_floor() -> void:
	if not lost and not floor_cleared and not campaign_won:
		message = "Clear this wave or let the core fall before advancing."
		message_clock = 2.0
		return
	if campaign_won:
		floor_cleared = false
		floor_number = 1
		campaign_won = false
		lost = false
		core_hp = core_max_hp
		_start_wave()
	elif floor_cleared:
		floor_cleared = false
		if floor_number >= FLOOR_COUNT:
			campaign_won = true
			lost = false
			message = "100 FLOORS CLEARED — endless mode unlocked!"
			message_clock = 999.0
			_save_game()
			return
		floor_number += 1
		wave_number = 1
		lost = false
		core_max_hp += 4.0
		core_hp = core_max_hp
		_start_wave()
	else:
		# Defeat retry: preserve permanent upgrades and restore a portion of core health.
		floor_cleared = false
		lost = false
		core_hp = maxf(35.0, core_max_hp * 0.65)
		_start_wave()
	_save_game()

func _draw() -> void:
	var viewport := get_viewport_rect().size
	var center := Vector2(viewport.x * 0.5, viewport.y * 0.49)
	var outer_radius := minf(viewport.x * 0.46, viewport.y * 0.32)
	draw_circle(center, outer_radius + 24, Color(0.10, 0.05, 0.15, 0.75))
	draw_arc(center, outer_radius + 14, 0, TAU, 96, Color(0.35, 0.22, 0.47), 4.0, true)
	for i in range(24):
		var a := TAU * float(i) / 24.0
		var p1 := center + Vector2(cos(a), sin(a)) * (outer_radius + 2)
		var p2 := center + Vector2(cos(a), sin(a)) * (outer_radius + 12)
		draw_line(p1, p2, Color(0.62, 0.37, 0.72), 2.0, true)
	# Defensive rune circle.
	draw_arc(center, outer_radius * 0.60, 0, TAU, 72, Color(0.35, 0.18, 0.55, 0.7), 2.0, true)
	for i in range(6):
		var a := TAU * float(i) / 6.0 + game_clock * 0.04
		var rune := center + Vector2(cos(a), sin(a)) * outer_radius * 0.60
		draw_colored_polygon(PackedVector2Array([rune + Vector2(0, -10), rune + Vector2(7, 0), rune + Vector2(0, 10), rune + Vector2(-7, 0)]), Color(0.45, 0.24, 0.7, 0.75))
	# The original crystal is drawn procedurally to keep this first slice asset-independent.
	var pulse := 1.0 + sin(game_clock * 2.5) * 0.06
	var core := PackedVector2Array([
		center + Vector2(0, -43 * pulse), center + Vector2(30 * pulse, -5),
		center + Vector2(18, 35), center + Vector2(-18, 35),
		center + Vector2(-30 * pulse, -5)
	])
	draw_colored_polygon(core, Color(0.36, 0.13, 0.65))
	draw_polyline(PackedVector2Array([core[0], core[1], core[2], core[3], core[4], core[0]]), Color(0.83, 0.64, 1.0), 3.0, true)
	draw_line(center + Vector2(0, -26), center + Vector2(0, 22), Color(0.95, 0.83, 1.0), 3.0, true)
	draw_arc(center, 52, 0, TAU, 40, Color(0.75, 0.4, 1.0, 0.65), 3.0, true)
	# Enemies are original stylized geometric silhouettes with role-specific colors.
	for enemy in enemies:
		var angle: float = enemy["angle"]
		var distance: float = enemy["distance"]
		var pos := center + Vector2(cos(angle), sin(angle)) * distance
		var color := _enemy_color(int(enemy["kind"]))
		var size := 13.0 if not enemy["boss"] else 25.0
		draw_circle(pos, size + 4, Color(color.r, color.g, color.b, 0.18))
		draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -size), pos + Vector2(size, 0), pos + Vector2(0, size), pos + Vector2(-size, 0)]), color)
		var hp_ratio := clampf(float(enemy["hp"]) / maxf(1.0, float(enemy["max_hp"])), 0, 1)
		draw_rect(Rect2(pos + Vector2(-18, size + 5), Vector2(36, 4)), Color(0.12, 0.08, 0.12))
		draw_rect(Rect2(pos + Vector2(-18, size + 5), Vector2(36 * hp_ratio, 4)), Color(0.45, 0.93, 0.48))
	# Attack streaks are effects only; damage is handled in the simulation.
	for shot in shots:
		var angle: float = shot["angle"]
		var distance: float = shot["distance"]
		var pos := center + Vector2(cos(angle), sin(angle)) * distance
		var end := center + Vector2(cos(angle), sin(angle)) * maxf(40, distance - 32)
		draw_line(pos, end, shot["color"], 3.0, true)
	# Core health bar.
	var bar := Rect2(center.x - 112, center.y + 68, 224, 10)
	draw_rect(bar, Color(0.12, 0.08, 0.16))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(core_hp / maxf(1.0, core_max_hp), 0, 1), bar.size.y)), Color(0.68, 0.25, 0.92))
	if shield > 0:
		draw_arc(center, 62, 0, TAU, 48, Color(0.25, 0.8, 1.0, 0.8), 3.0, true)

func _enemy_color(kind: int) -> Color:
	match kind:
		0: return Color(0.88, 0.30, 0.36)
		1: return Color(0.94, 0.63, 0.25)
		2: return Color(0.63, 0.43, 0.98)
		3: return Color(0.30, 0.87, 0.56)
		4: return Color(0.38, 0.82, 0.91)
		5: return Color(0.68, 0.67, 0.72)
		6: return Color(0.91, 0.76, 0.32)
		_: return Color(0.98, 0.25, 0.63)

func _save_game() -> void:
	var data := {
		"version": 1,
		"floor": floor_number,
		"wave": wave_number,
		"core_hp": core_hp,
		"core_max_hp": core_max_hp,
		"gold": gold,
		"souls": souls,
		"research_points": research_points,
		"core_damage": core_damage,
		"attack_rate": attack_rate,
		"research_level": research_level,
		"guardian_level": guardian_level,
		"defeated": defeated,
		"lost": lost,
		"floor_cleared": floor_cleared,
		"campaign_won": campaign_won,
		"last_saved_unix": int(Time.get_unix_time_from_system())
	}
	var file := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		push_error("Could not open temporary save file.")
		return
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_PATH + ".tmp"), ProjectSettings.globalize_path(SAVE_PATH))
	if err != OK:
		push_error("Could not replace save file: %s" % error_string(err))
		return
	last_saved_unix = int(data["last_saved_unix"])

func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		message = "Save unavailable. A new run is ready."
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		message = "Save data was invalid; starting a new run."
		return
	var data: Dictionary = parsed
	var version := int(data.get("version", 0))
	if version > 1 or version < 1:
		message = "Save version unsupported; starting a new run."
		return
	floor_number = clampi(int(data.get("floor", 1)), 1, FLOOR_COUNT)
	wave_number = max(1, int(data.get("wave", 1)))
	core_max_hp = maxf(100, float(data.get("core_max_hp", 100)))
	core_hp = clampf(float(data.get("core_hp", core_max_hp)), 0, core_max_hp)
	gold = maxi(0, int(data.get("gold", 0)))
	souls = maxi(0, int(data.get("souls", 0)))
	research_points = maxi(0, int(data.get("research_points", 0)))
	core_damage = maxf(1, float(data.get("core_damage", 12)))
	attack_rate = maxf(0.1, float(data.get("attack_rate", 0.8)))
	research_level = maxi(0, int(data.get("research_level", 0)))
	guardian_level = maxi(1, int(data.get("guardian_level", 1)))
	defeated = maxi(0, int(data.get("defeated", 0)))
	lost = bool(data.get("lost", false))
	floor_cleared = bool(data.get("floor_cleared", false))
	campaign_won = bool(data.get("campaign_won", false))
	last_saved_unix = int(data.get("last_saved_unix", Time.get_unix_time_from_system()))
	var elapsed := clampi(int(Time.get_unix_time_from_system()) - last_saved_unix, 0, MAX_OFFLINE_SECONDS)
	var reward := int(elapsed / 60.0) * (1 + research_level / 3)
	gold += reward
	if reward > 0:
		offline_summary = "Offline reward: %d gold for %d minutes." % [reward, int(elapsed / 60)]
	# A loaded session starts a fresh wave; combat is never simulated while offline.
	_start_wave()
	if reward > 0:
		message = offline_summary
		message_clock = 8.0
	# Immediately persist the new timestamp so reopening cannot claim the same interval again.
	_save_game()

func _reset_save() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Reset local save?"
	dialog.dialog_text = "This deletes local progress. This cannot be undone."
	ui_layer.add_child(dialog)
	dialog.confirmed.connect(func():
		if FileAccess.file_exists(SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		get_tree().reload_current_scene()
	)
	dialog.popup_centered()
