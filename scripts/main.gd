extends Node2D
## First playable slice: automatic 360-degree core defense, touch upgrades,
## 100-floor progression, milestone bosses, local saves and capped offline gold.
## All combat outcomes are simulated here; _draw() only visualizes game state.

const SAVE_PATH := "user://core_guardian_save.json"
const SAVE_VERSION := 3
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
var hero_atlas: Texture2D
var background_art: Texture2D
var floor_definitions: Array = []
var guardian_definitions: Array = []
var enemy_definitions: Array = []
var research_definitions: Array = []
var relic_definitions: Array = []
var unlocked_relics: Array = []
var relic_fragments := 0
var collection_overlay: Control
var reduced_effects := false
var enemies: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var floor_number := 1
var wave_number := 1
var waves_per_floor := 4
var enemy_spawn_limit := 3
var core_hp := 100.0
var core_max_hp := 100.0
var gold := 0
var souls := 0
var research_points := 0
var core_damage := 12.0
var core_evolution := "infernal"
var attack_rate := 0.8
var shield := 0.0
var research_level := 0
var guardian_level := 1
var guardian_count := 1
var guardian_skill_clock := 0.0
var defeated := 0
var wave_spawned := 0
var spawn_clock := 0.0
var attack_clock := 0.0
var game_clock := 0.0
var lost := false
var floor_cleared := false
var campaign_won := false
var endless_mode := false
var message := "The heroes are coming. Protect the core."
var message_clock := 5.0
var selected_panel := "battle"
var offline_summary := ""
var last_saved_unix := 0
var skill_cooldown := 0.0
var skill_ready := true
var screen_size := Vector2(720, 1280)
var ui_layer: CanvasLayer
var menu_overlay: Control
var menu_open := true
var hud_label: Label
var status_label: Label
var buttons: Array[Button] = []
var research_selector: OptionButton
var research_ranks: Dictionary = {"core_mastery": 0, "demonology": 0, "engineering": 0, "soul_alchemy": 0, "lordship": 0}

func _ready() -> void:
	rng.randomize()
	screen_size = get_viewport_rect().size
	hero_atlas = load("res://assets/characters/hero_atlas.svg")
	background_art = load("res://assets/environments/outer_gate.svg")
	_load_floor_content()
	guardian_definitions = _load_content_array("res://content/guardians.json", "guardians")
	enemy_definitions = _load_content_array("res://content/enemies.json", "archetypes")
	research_definitions = _load_content_array("res://content/research.json", "branches")
	relic_definitions = _load_content_array("res://content/relics.json", "relics")
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
	if not menu_open and not lost and not campaign_won:
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
	var y := 980.0
	_add_button(root, "UPGRADE CORE  ·  %s gold" % _upgrade_cost(), Rect2(22, y, 328, 72), _upgrade_core)
	_add_button(root, "SUMMON GUARDIAN  ·  %s souls" % _summon_cost(), Rect2(366, y, 332, 72), _summon_guardian)
	_add_button(root, "EMERGENCY SHIELD", Rect2(22, y + 82, 328, 72), _cast_shield)
	research_selector = OptionButton.new()
	research_selector.position = Vector2(366, y + 82)
	research_selector.size = Vector2(332, 72)
	research_selector.add_theme_font_size_override("font_size", 17)
	research_selector.add_theme_stylebox_override("normal", _button_style(Color(0.19, 0.10, 0.29)))
	for branch in research_definitions:
		research_selector.add_item(str(branch.get("name", "Research")))
	if research_selector.item_count > 0:
		research_selector.select(0)
	research_selector.item_selected.connect(_on_research_branch_selected)
	root.add_child(research_selector)
	_add_button(root, "NEXT FLOOR / RETRY", Rect2(22, y + 164, 676, 60), _next_floor)
	_add_button(root, "EVOLVE CORE  ·  3 research", Rect2(22, y + 234, 328, 52), _evolve_core)
	_add_button(root, "BUY RESEARCH  ·  %d gold / 1 point" % _research_cost(), Rect2(366, y + 234, 332, 52), _buy_research)
	_update_ui()
	_build_main_menu()

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

func _build_main_menu() -> void:
	menu_overlay = Control.new()
	menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(menu_overlay)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.025, 0.018, 0.05, 0.96)
	menu_overlay.add_child(shade)
	var title := Label.new()
	title.text = "CORE GUARDIAN\nDEMON LORD'S TOWER"
	title.position = Vector2(35, 300)
	title.size = Vector2(650, 125)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.95, 0.77, 0.48))
	menu_overlay.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "You are the Demon Lord. Protect the core.\nThe heroes must destroy it before they reach your throne."
	subtitle.position = Vector2(45, 430)
	subtitle.size = Vector2(630, 70)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 17)
	subtitle.add_theme_color_override("font_color", Color(0.84, 0.79, 0.91))
	menu_overlay.add_child(subtitle)
	_add_menu_button(menu_overlay, "CONTINUE TOWER", Rect2(110, 510, 500, 60), _enter_tower)
	_add_menu_button(menu_overlay, "NEW GAME", Rect2(110, 580, 500, 60), _confirm_new_game)
	_add_menu_button(menu_overlay, "GUARDIANS & RELICS", Rect2(110, 650, 500, 60), _open_collection)
	_add_menu_button(menu_overlay, "TOWER MAP", Rect2(110, 720, 500, 60), _open_tower_map)
	_add_menu_button(menu_overlay, "SETTINGS", Rect2(110, 790, 500, 60), _open_settings)
	_add_menu_button(menu_overlay, "QUIT", Rect2(110, 860, 500, 60), func(): get_tree().quit())

func _add_menu_button(parent: Control, text_value: String, rect: Rect2, action: Callable) -> void:
	var button := Button.new()
	button.text = text_value
	button.position = rect.position
	button.size = rect.size
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color(0.97, 0.94, 1.0))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.19, 0.10, 0.29)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.34, 0.15, 0.40)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.45, 0.22, 0.34)))
	button.pressed.connect(action)
	parent.add_child(button)

func _open_collection() -> void:
	_show_menu_panel("GUARDIANS & RELICS")
	var body := Label.new()
	var text_lines := ["GUARDIAN ROSTER"]
	for guardian in guardian_definitions:
		text_lines.append("• %s — %s" % [str(guardian.get("name", "Unknown Guardian")), str(guardian.get("role", "Guardian"))])
	text_lines.append("")
	text_lines.append("RELIC COLLECTION  ·  Fragments: %d" % relic_fragments)
	if unlocked_relics.is_empty():
		text_lines.append("No relics collected yet. Defeat milestone bosses to earn relics.")
	else:
		for relic in relic_definitions:
			if unlocked_relics.has(str(relic.get("id", ""))):
				text_lines.append("• %s — %s" % [str(relic.get("name", "Relic")), str(relic.get("effect", "Unknown effect"))])
	body.text = "\n".join(text_lines)
	body.position = Vector2(48, 150)
	body.size = Vector2(624, 590)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 18)
	body.add_theme_color_override("font_color", Color(0.88, 0.84, 0.94))
	collection_overlay.add_child(body)
	_add_menu_button(collection_overlay, "BACK TO MENU", Rect2(110, 790, 500, 60), _close_menu_panel)

func _open_tower_map() -> void:
	_show_menu_panel("100-FLOOR TOWER MAP")
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(38, 140)
	scroll.size = Vector2(644, 600)
	collection_overlay.add_child(scroll)
	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(610, 0)
	scroll.add_child(list)
	for floor_data in floor_definitions:
		var n := int(floor_data.get("floor", 1))
		var status := "CLEARED" if n < floor_number else ("CURRENT" if n == floor_number else "LOCKED")
		var boss_text := "  ·  BOSS: " + str(floor_data.get("boss_name", "")) if bool(floor_data.get("boss_floor", false)) else ""
		var row := Label.new()
		row.text = "FLOOR %03d  ·  %s  ·  %s%s" % [n, str(floor_data.get("region", "Unknown Region")), status, boss_text]
		row.custom_minimum_size = Vector2(610, 38)
		row.add_theme_font_size_override("font_size", 15)
		row.add_theme_color_override("font_color", Color(0.95, 0.77, 0.48) if status == "CURRENT" else Color(0.75, 0.72, 0.83))
		list.add_child(row)
	_add_menu_button(collection_overlay, "BACK TO MENU", Rect2(110, 790, 500, 60), _close_menu_panel)

func _open_settings() -> void:
	_show_menu_panel("SETTINGS")
	var description := Label.new()
	description.text = "Autosave: enabled\nOffline earnings: maximum 8 hours\nNetwork connection: not required"
	description.position = Vector2(55, 260)
	description.size = Vector2(610, 120)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.add_theme_font_size_override("font_size", 18)
	description.add_theme_color_override("font_color", Color(0.85, 0.82, 0.92))
	collection_overlay.add_child(description)
	var effects := CheckButton.new()
	effects.text = "Reduce visual effects"
	effects.position = Vector2(100, 420)
	effects.size = Vector2(520, 65)
	effects.button_pressed = reduced_effects
	effects.add_theme_font_size_override("font_size", 21)
	effects.toggled.connect(_set_reduced_effects)
	collection_overlay.add_child(effects)
	_add_menu_button(collection_overlay, "BACK TO MENU", Rect2(110, 790, 500, 60), _close_menu_panel)

func _show_menu_panel(panel_title: String) -> void:
	menu_overlay.visible = false
	collection_overlay = Control.new()
	collection_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(collection_overlay)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.025, 0.018, 0.05, 0.98)
	collection_overlay.add_child(shade)
	var title := Label.new()
	title.text = panel_title
	title.position = Vector2(30, 65)
	title.size = Vector2(660, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.95, 0.77, 0.48))
	collection_overlay.add_child(title)

func _close_menu_panel() -> void:
	if is_instance_valid(collection_overlay):
		collection_overlay.queue_free()
	menu_overlay.visible = true

func _set_reduced_effects(enabled: bool) -> void:
	reduced_effects = enabled
	_save_game()
	queue_redraw()

func _enter_tower() -> void:
	menu_open = false
	menu_overlay.visible = false
	message = "Defend the core. Heroes approach from every direction."
	message_clock = 3.0
	_save_game()

func _confirm_new_game() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Start a new tower run?"
	dialog.dialog_text = "This resets local campaign progress, research, guardians and resources."
	ui_layer.add_child(dialog)
	dialog.confirmed.connect(_new_game)
	dialog.popup_centered()

func _new_game() -> void:
	floor_number = 1
	wave_number = 1
	endless_mode = false
	core_hp = 100.0
	core_max_hp = 100.0
	core_damage = 12.0
	core_evolution = "infernal"
	attack_rate = 0.8
	shield = 0.0
	gold = 0
	souls = 0
	research_points = 0
	relic_fragments = 0
	unlocked_relics.clear()
	research_level = 0
	research_ranks = {"core_mastery": 0, "demonology": 0, "engineering": 0, "soul_alchemy": 0, "lordship": 0}
	guardian_level = 1
	guardian_count = 1
	guardian_skill_clock = 0.0
	skill_cooldown = 0.0
	skill_ready = true
	defeated = 0
	lost = false
	floor_cleared = false
	campaign_won = false
	enemies.clear()
	shots.clear()
	for path in [SAVE_PATH, SAVE_PATH + ".bak", SAVE_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_start_wave()
	menu_open = false
	menu_overlay.visible = false
	_save_game()
	_update_ui()

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


func _load_content_array(path: String, key: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Content file missing: " + path)
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Content file is invalid: " + path)
		return []
	var data: Dictionary = parsed
	var value: Variant = data.get(key, [])
	if typeof(value) != TYPE_ARRAY:
		push_warning("Content array is missing: " + key)
		return []
	return value

func _floor_definition() -> Dictionary:
	if floor_number > FLOOR_COUNT:
		return {"floor": floor_number, "region": "Endless Spire", "boss_floor": floor_number % 10 == 0, "boss_name": "Endless Champion", "wave_count": mini(12, 4 + int(floor_number / 8))}
	if floor_definitions.is_empty():
		return {}
	var index := clampi(floor_number - 1, 0, floor_definitions.size() - 1)
	var value: Variant = floor_definitions[index]
	return value if typeof(value) == TYPE_DICTIONARY else {}

func _update_ui() -> void:
	if not is_instance_valid(hud_label):
		return
	var region: String = str(_floor_definition().get("region", REGION_NAMES[mini(9, int((floor_number - 1) / 10))]))
	var floor_label := "FLOOR %03d / 100" % floor_number if floor_number <= FLOOR_COUNT else "ENDLESS FLOOR %03d" % floor_number
	hud_label.text = "%s  ·  WAVE %d/%d\nCORE  %.0f/%.0f   ·   SHIELD %.0f\nGOLD %d   SOULS %d   RESEARCH %d   FRAGMENTS %d" % [floor_label, wave_number, waves_per_floor, maxf(0, core_hp), core_max_hp, shield, gold, souls, research_points, relic_fragments]
	status_label.text = "%s  |  Core: %s  |  Guardians %d · Lv.%d  |  %s" % [region, core_evolution.capitalize(), guardian_count, guardian_level, message if message_clock > 0 else "Automatic defenses active."]
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
			"BUY RESEARCH":
				button.text = "BUY RESEARCH  ·  %d gold / 1 point" % _research_cost()
				button.disabled = gold < _research_cost() or research_points < 1
			"EVOLVE CORE":
				button.text = "EVOLVE CORE  ·  3 research"
				button.disabled = research_points < 3 or lost or campaign_won
			"EMERGENCY SHIELD":
				button.text = "EMERGENCY SHIELD  ·  %s" % ("READY" if skill_ready else "%.1fs" % skill_cooldown)
				button.disabled = not skill_ready or lost or campaign_won

func _upgrade_cost() -> int:
	return 25 + int(core_damage * 2.0) + floor_number * 3

func _summon_cost() -> int:
	return 4 + guardian_count * 3 + guardian_level * 2

func _research_cost() -> int:
	return 40 + research_level * 30

func _start_wave() -> void:
	enemies.clear()
	shots.clear()
	wave_spawned = 0
	spawn_clock = 0.0
	attack_clock = 0.0
	waves_per_floor = int(_floor_definition().get("wave_count", 4 + int(floor_number / 8)))
	waves_per_floor = clampi(waves_per_floor, 1, 12)
	enemy_spawn_limit = 3 + int(floor_number / 20)
	if bool(_floor_definition().get("boss_floor", floor_number % 10 == 0)):
		waves_per_floor = 1
		enemy_spawn_limit = 1
	message = "Floor %d, wave %d/%d: invasion begins." % [floor_number, wave_number, waves_per_floor]
	message_clock = 3.0

func _update_combat(delta: float) -> void:
	spawn_clock += delta
	attack_clock += delta
	if wave_spawned < enemy_spawn_limit and spawn_clock >= maxf(0.35, 1.5 - floor_number * 0.006):
		spawn_clock = 0.0
		_spawn_enemy()
	if attack_clock >= maxf(0.18, 1.0 / (attack_rate + research_level * 0.025)):
		attack_clock = 0.0
		_core_attack()
		_guardian_attack()
	for i in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[i]
		var kind := int(enemy["kind"])
		var distance := float(enemy["distance"]) - float(enemy["speed"]) * delta
		enemy["angle"] = float(enemy["angle"]) + float(enemy["turn"]) * delta
		enemy["special_clock"] = float(enemy.get("special_clock", 0.0)) + delta

		# Rangers stop at range and fire at the core instead of charging into melee.
		if kind == 1 and not bool(enemy["boss"]) and distance <= 160.0:
			distance = maxf(150.0, distance)
			enemy["ranged_clock"] = float(enemy.get("ranged_clock", 0.0)) + delta
			if float(enemy["ranged_clock"]) >= 1.35:
				enemy["ranged_clock"] = 0.0
				_damage_core(float(enemy["damage"]) * 0.65)
				if lost:
					return
		# Battle mages periodically blast the core from mid-range.
		elif kind == 2 and distance <= 210.0:
			if float(enemy["special_clock"]) >= 2.4:
				enemy["special_clock"] = 0.0
				_damage_core(float(enemy["damage"]) * 0.8)
				if lost:
					return
		# Field medics heal a nearby injured hero, extending coordinated assaults.
		elif kind == 3 and float(enemy["special_clock"]) >= 2.5:
			enemy["special_clock"] = 0.0
			var healed_index := -1
			var lowest_ratio := 1.0
			for ally_index in range(enemies.size()):
				if ally_index == i:
					continue
				var ally: Dictionary = enemies[ally_index]
				var ratio := float(ally["hp"]) / maxf(1.0, float(ally["max_hp"]))
				if ratio < lowest_ratio and absf(float(ally["distance"]) - distance) < 125.0:
					lowest_ratio = ratio
					healed_index = ally_index
			if healed_index >= 0:
				var ally: Dictionary = enemies[healed_index]
				ally["hp"] = minf(float(ally["max_hp"]), float(ally["hp"]) + float(ally["max_hp"]) * 0.08)
				enemies[healed_index] = ally
				message = "Field Medic restores a hero."
				message_clock = 1.2

		# Boss attacks telegraph before impact; the final phase deals more damage.
		if bool(enemy["boss"]) and distance <= 230.0:
			enemy["telegraph_clock"] = float(enemy.get("telegraph_clock", 0.0))
			if float(enemy["special_clock"]) >= 3.2 and float(enemy["telegraph_clock"]) <= 0.0:
				enemy["special_clock"] = 0.0
				enemy["telegraph_clock"] = 0.85
				message = "%s is charging a core-breaking technique!" % enemy["name"]
				message_clock = 1.0
			if float(enemy["telegraph_clock"]) > 0.0:
				enemy["telegraph_clock"] = maxf(0.0, float(enemy["telegraph_clock"]) - delta)
				if float(enemy["telegraph_clock"]) <= 0.0:
					var hp_ratio := float(enemy["hp"]) / maxf(1.0, float(enemy["max_hp"]))
					var phase_damage := 0.35 if hp_ratio > 0.33 else 0.65
					_damage_core(float(enemy["damage"]) * phase_damage)
					message = "%s unleashes the core-breaking technique!" % enemy["name"]
					message_clock = 1.6
					if lost:
						return

		enemy["distance"] = distance
		if kind != 1 and distance <= 100.0:
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
	if wave_spawned >= enemy_spawn_limit and enemies.is_empty():
		_complete_wave()

func _enemy_name(kind: int) -> String:
	if kind >= 0 and kind < enemy_definitions.size():
		return str(enemy_definitions[kind].get("name", ENEMY_NAMES[clampi(kind, 0, ENEMY_NAMES.size() - 1)]))
	return ENEMY_NAMES[clampi(kind, 0, ENEMY_NAMES.size() - 1)]

func _spawn_enemy() -> void:
	var boss := bool(_floor_definition().get("boss_floor", floor_number % 10 == 0))
	var kind := 7 if boss else rng.randi_range(0, mini(7, int(floor_number / 12) + 2))
	var scale := 1.0 + floor_number * 0.105
	var hp := (75.0 + floor_number * 13.0) * scale
	var speed := 17.0 + minf(12.0, floor_number * 0.08)
	var damage := 5.0 + floor_number * 0.6
	if not boss:
		match kind:
			0: # Vanguard: durable frontline.
				hp *= 1.3
				speed *= 0.9
			1: # Ranger: lower health, attacks from range.
				hp *= 0.8
				speed *= 0.82
				damage *= 0.8
			2: # Battle Mage: medium health, dangerous ranged burst.
				hp *= 0.9
				speed *= 0.9
				damage *= 1.15
			3: # Field Medic: fragile support.
				hp *= 0.72
				speed *= 0.82
				damage *= 0.55
			4: # Shadow Assassin: fast, fragile infiltrator.
				hp *= 0.68
				speed *= 1.55
				damage *= 1.25
			5: # Siege Golem: slow and heavily armored.
				hp *= 2.25
				speed *= 0.52
				damage *= 1.7
			6: # Relic Hunter: durable specialist.
				hp *= 1.25
				speed *= 0.92
	if boss:
		hp *= 9.0
		speed *= 0.68
		damage *= 3.2
	var angle := rng.randf_range(0.0, TAU)
	var enemy := {
		"kind": kind,
		"name": str(_floor_definition().get("boss_name", "Floor %d Boss" % floor_number)) if boss else _enemy_name(kind),
		"angle": angle,
		"distance": 410.0,
		"hp": hp,
		"max_hp": hp,
		"speed": speed,
		"damage": damage,
		"turn": rng.randf_range(-0.12, 0.12),
		"attack_clock": 0.0,
		"special_clock": 0.0,
		"telegraph_clock": 0.0,
		"ranged_clock": 0.0,
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
	var damage := core_damage + research_level * 2.5
	if core_evolution == "infernal":
		damage *= 1.25
	if unlocked_relics.has("shard_of_the_first_demon"):
		damage *= 1.08
	target["hp"] = float(target["hp"]) - damage
	enemies[target_index] = target
	shots.append({"angle": float(target["angle"]), "distance": float(target["distance"]), "life": 0.16, "color": Color(0.65, 0.35, 1.0)})

func _guardian_attack() -> void:
	if enemies.is_empty() or guardian_count <= 0:
		return
	guardian_skill_clock += 1.0
	for guardian_index in range(guardian_count):
		if enemies.is_empty():
			break
		var guardian_kind := guardian_index % 5
		var target_index := -1
		var closest_distance := INF
		# Morveth prioritizes enemy support roles; Varkhan and Grum protect the frontline.
		for enemy_index in range(enemies.size()):
			var candidate: Dictionary = enemies[enemy_index]
			var candidate_kind := int(candidate["kind"])
			var preferred := guardian_kind == 2 and (candidate_kind == 3 or candidate_kind == 2)
			var distance_value := float(candidate["distance"]) - (10000.0 if preferred else 0.0)
			if distance_value < closest_distance:
				closest_distance = distance_value
				target_index = enemy_index
		if target_index < 0:
			continue
		var enemy: Dictionary = enemies[target_index]
		var damage := 7.0 * guardian_level
		match guardian_kind:
			0: # Varkhan: heavy frontline strike.
				damage = 14.0 * guardian_level
			1: # Nyxara: chained soul bolts.
				damage = 9.0 * guardian_level
			2: # Morveth: precise execution shot.
				damage = 18.0 * guardian_level
				if int(enemy["kind"]) == 2 or int(enemy["kind"]) == 3:
					damage *= 1.6
					if unlocked_relics.has("healer_bane") and int(enemy["kind"]) == 3:
						damage *= 1.15
			3: # Grum: defensive support.
				damage = 5.0 * guardian_level
				if int(guardian_skill_clock) % 3 == 0:
					shield += 3.0 * guardian_level
			4: # Zippi: rapid chaotic fire.
				damage = 6.0 * guardian_level
		enemy["hp"] = float(enemy["hp"]) - damage
		enemies[target_index] = enemy
		shots.append({"angle": float(enemy["angle"]), "distance": float(enemy["distance"]), "life": 0.15, "color": Color(0.2, 0.92, 0.78)})
		if guardian_kind == 1 and enemies.size() > 1:
			var chain_index := (target_index + 1) % enemies.size()
			var chained: Dictionary = enemies[chain_index]
			chained["hp"] = float(chained["hp"]) - 3.0 * guardian_level
			enemies[chain_index] = chained
		if guardian_kind == 4 and enemies.size() > 1:
			var second_index := rng.randi_range(0, enemies.size() - 1)
			var second: Dictionary = enemies[second_index]
			second["hp"] = float(second["hp"]) - 3.0 * guardian_level
			enemies[second_index] = second

func _damage_core(amount: float) -> void:
	if core_evolution == "abyssal":
		amount *= 0.8
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
	if core_evolution == "soulbound":
		gold += 2 + int(floor_number / 10)
		souls += 1
	if defeated % 5 == 0:
		research_points += 1
	message = "%s defeated. The tower claims its reward." % enemy["name"]
	message_clock = 2.0

func _unlock_relic_for_floor() -> void:
	for relic in relic_definitions:
		var relic_id := str(relic.get("id", ""))
		if relic_id.is_empty() or unlocked_relics.has(relic_id):
			continue
		if int(relic.get("unlock_floor", 999)) <= floor_number:
			unlocked_relics.append(relic_id)
			message = "Relic acquired: %s" % str(relic.get("name", relic_id))
			message_clock = 4.0
			return

func _complete_wave() -> void:
	if lost or floor_cleared or campaign_won:
		return
	gold += 10 + floor_number * 2
	if wave_number < waves_per_floor:
		wave_number += 1
		message = "Wave cleared. The next hero party is approaching."
		message_clock = 3.0
		_start_wave()
		_save_game()
		return
	gold += 15 + floor_number * 3
	if bool(_floor_definition().get("boss_floor", floor_number % 10 == 0)):
		research_points += 3
		souls += 8
		relic_fragments += 3
		_unlock_relic_for_floor()
		if unlocked_relics.has("dragon_heart"):
			gold += int(float(gold) * 0.12)
		message = "%s defeated. Floor %d cleared." % [str(_floor_definition().get("boss_name", "Milestone boss")), floor_number]
	else:
		message = "All invasion waves defeated. Floor %d cleared." % floor_number
	message_clock = 5.0
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
	if guardian_count < mini(5, maxi(1, guardian_definitions.size())):
		guardian_count += 1
		var new_name := GUARDIAN_NAMES[(guardian_count - 1) % GUARDIAN_NAMES.size()]
		if guardian_count - 1 < guardian_definitions.size():
			new_name = str(guardian_definitions[guardian_count - 1].get("name", new_name))
		message = "%s joined your defense." % new_name
	else:
		guardian_level += 1
		message = "All guardians strengthened to level %d." % guardian_level
	message_clock = 2.5

func _evolve_core() -> void:
	if research_points < 3 or lost or campaign_won:
		return
	research_points -= 3
	match core_evolution:
		"infernal":
			core_evolution = "abyssal"
			shield += core_max_hp * 0.2
			message = "Abyssal Core awakened: incoming damage reduced."
		"abyssal":
			core_evolution = "soulbound"
			message = "Soulbound Core awakened: defeated heroes yield extra resources."
		_:
			core_evolution = "infernal"
			message = "Infernal Core awakened: core attacks deal increased damage."
	message_clock = 3.0
	_save_game()

func _cast_shield() -> void:
	if not skill_ready or lost or campaign_won:
		return
	shield += (35.0 + research_level * 5.0) * (1.1 if unlocked_relics.has("broken_halo") else 1.0)
	skill_ready = false
	skill_cooldown = maxf(8.0, 20.0 - float(research_ranks.get("lordship", 0)) * 1.5)
	message = "Emergency Shield absorbed incoming damage."
	message_clock = 2.0

func _on_research_branch_selected(index: int) -> void:
	if research_selector != null:
		research_selector.select(clampi(index, 0, 4))

func _buy_research() -> void:
	var cost := _research_cost()
	if gold < cost or research_points < 1:
		message = "Research requires %d gold and 1 research point." % cost
		message_clock = 2.0
		return
	gold -= cost
	research_points -= 1
	var branch_id := "core_mastery"
	if not research_definitions.is_empty():
		var branch_data: Dictionary = research_definitions[clampi(research_selector.selected, 0, research_definitions.size() - 1)]
		branch_id = str(branch_data.get("id", branch_id))
	research_ranks[branch_id] = int(research_ranks.get(branch_id, 0)) + 1
	research_level += 1
	match branch_id:
		"core_mastery":
			core_max_hp += 10.0
			core_hp = minf(core_max_hp, core_hp + 10.0)
			core_damage += 1.5
		"demonology":
			guardian_level += 1
		"engineering":
			attack_rate += 0.08
		"soul_alchemy":
			# Offline time stays capped; research improves gold per offline minute.
			gold += 0
		"lordship":
			skill_cooldown = maxf(0.0, skill_cooldown - 2.0)
	message = "%s research advanced to rank %d." % [branch_id.replace("_", " ").capitalize(), research_ranks[branch_id]]
	message_clock = 2.5
	_save_game()

func _next_floor() -> void:
	if not lost and not floor_cleared and not campaign_won:
		message = "Clear this wave or let the core fall before advancing."
		message_clock = 2.0
		return
	if campaign_won:
		floor_cleared = false
		endless_mode = true
		floor_number = FLOOR_COUNT + 1
		wave_number = 1
		campaign_won = false
		lost = false
		core_hp = core_max_hp
		message = "Endless Spire begins. Every tenth floor brings an Endless Champion."
		message_clock = 5.0
		_start_wave()
	elif floor_cleared:
		floor_cleared = false
		if floor_number >= FLOOR_COUNT and not endless_mode:
			campaign_won = true
			lost = false
			message = "100 FLOORS CLEARED — tap NEXT FLOOR to enter endless survival."
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
	if background_art != null:
		draw_texture_rect(background_art, Rect2(Vector2.ZERO, viewport), false, Color.WHITE)
	var region_tints := [
		Color(0.20, 0.08, 0.25, 0.10), Color(0.08, 0.12, 0.22, 0.14),
		Color(0.06, 0.20, 0.14, 0.12), Color(0.22, 0.13, 0.06, 0.12),
		Color(0.13, 0.09, 0.25, 0.14), Color(0.25, 0.05, 0.13, 0.12),
		Color(0.25, 0.08, 0.03, 0.13), Color(0.08, 0.14, 0.25, 0.14),
		Color(0.10, 0.02, 0.19, 0.16), Color(0.16, 0.03, 0.08, 0.14)
	]
	draw_rect(Rect2(Vector2.ZERO, viewport), region_tints[mini(9, int((floor_number - 1) / 10))], false)
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
		if bool(enemy["boss"]) and float(enemy.get("telegraph_clock", 0.0)) > 0.0:
			draw_arc(center, distance, angle - 0.24, angle + 0.24, 18, Color(1.0, 0.18, 0.3, 0.95), 5.0, true)
			draw_line(pos, center, Color(1.0, 0.18, 0.3, 0.55), 3.0, true)
		if not reduced_effects:
			draw_circle(pos, size + 4, Color(color.r, color.g, color.b, 0.18))
		if hero_atlas != null:
			var bob := sin(game_clock * 5.0 + angle) * 2.0
			var source := Rect2(float(int(enemy["kind"]) * 100), 0, 100, 100)
			draw_texture_rect_region(hero_atlas, Rect2(pos + Vector2(-size, -size + bob), Vector2(size * 2.0, size * 2.0)), source, Color.WHITE, false, true)
		else:
			draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -size), pos + Vector2(size, 0), pos + Vector2(0, size), pos + Vector2(-size, 0)]), color)
		var hp_ratio := clampf(float(enemy["hp"]) / maxf(1.0, float(enemy["max_hp"])), 0, 1)
		draw_rect(Rect2(pos + Vector2(-18, size + 5), Vector2(36, 4)), Color(0.12, 0.08, 0.12))
		draw_rect(Rect2(pos + Vector2(-18, size + 5), Vector2(36 * hp_ratio, 4)), Color(0.45, 0.93, 0.48))
	# Attack streaks are effects only; damage is handled in the simulation.
	if not reduced_effects:
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
		"version": SAVE_VERSION,
		"floor": floor_number,
		"wave": wave_number,
		"core_hp": core_hp,
		"core_max_hp": core_max_hp,
		"gold": gold,
		"souls": souls,
		"research_points": research_points,
		"relic_fragments": relic_fragments,
		"unlocked_relics": unlocked_relics,
		"reduced_effects": reduced_effects,
		"core_damage": core_damage,
		"core_evolution": core_evolution,
		"attack_rate": attack_rate,
		"research_level": research_level,
		"research_ranks": research_ranks,
		"guardian_level": guardian_level,
		"guardian_count": guardian_count,
		"defeated": defeated,
		"lost": lost,
		"floor_cleared": floor_cleared,
		"campaign_won": campaign_won,
		"endless_mode": endless_mode,
		"last_saved_unix": int(Time.get_unix_time_from_system())
	}
	var file := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		push_error("Could not open temporary save file.")
		return
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	var main_path := ProjectSettings.globalize_path(SAVE_PATH)
	var temp_path := ProjectSettings.globalize_path(SAVE_PATH + ".tmp")
	var backup_path := ProjectSettings.globalize_path(SAVE_PATH + ".bak")
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_path)
	if FileAccess.file_exists(main_path):
		var backup_error := DirAccess.rename_absolute(main_path, backup_path)
		if backup_error != OK:
			push_error("Could not preserve previous save: %s" % error_string(backup_error))
			return
	var err := DirAccess.rename_absolute(temp_path, main_path)
	if err != OK:
		if FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(backup_path, main_path)
		push_error("Could not replace save file: %s" % error_string(err))
		return
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_path)
	last_saved_unix = int(data["last_saved_unix"])

func _load_game() -> void:
	var main_path := ProjectSettings.globalize_path(SAVE_PATH)
	var backup_path := ProjectSettings.globalize_path(SAVE_PATH + ".bak")
	if not FileAccess.file_exists(SAVE_PATH) and FileAccess.file_exists(backup_path):
		DirAccess.rename_absolute(backup_path, main_path)
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
	if version > SAVE_VERSION or version < 1:
		message = "Save version unsupported; starting a new run."
		return
	floor_number = clampi(int(data.get("floor", 1)), 1, 9999)
	wave_number = max(1, int(data.get("wave", 1)))
	core_max_hp = maxf(100, float(data.get("core_max_hp", 100)))
	core_hp = clampf(float(data.get("core_hp", core_max_hp)), 0, core_max_hp)
	gold = maxi(0, int(data.get("gold", 0)))
	souls = maxi(0, int(data.get("souls", 0)))
	research_points = maxi(0, int(data.get("research_points", 0)))
	relic_fragments = maxi(0, int(data.get("relic_fragments", 0)))
	var saved_relics: Variant = data.get("unlocked_relics", [])
	unlocked_relics = saved_relics if typeof(saved_relics) == TYPE_ARRAY else []
	reduced_effects = bool(data.get("reduced_effects", false))
	core_damage = maxf(1, float(data.get("core_damage", 12)))
	core_evolution = str(data.get("core_evolution", "infernal"))
	if not ["infernal", "abyssal", "soulbound"].has(core_evolution):
		core_evolution = "infernal"
	attack_rate = maxf(0.1, float(data.get("attack_rate", 0.8)))
	research_level = maxi(0, int(data.get("research_level", 0)))
	var saved_research: Variant = data.get("research_ranks", research_ranks)
	if typeof(saved_research) == TYPE_DICTIONARY:
		research_ranks = saved_research
	guardian_level = maxi(1, int(data.get("guardian_level", 1)))
	guardian_count = clampi(int(data.get("guardian_count", 1)), 1, 5)
	defeated = maxi(0, int(data.get("defeated", 0)))
	lost = bool(data.get("lost", false))
	floor_cleared = bool(data.get("floor_cleared", false))
	campaign_won = bool(data.get("campaign_won", false))
	endless_mode = bool(data.get("endless_mode", floor_number > FLOOR_COUNT))
	last_saved_unix = int(data.get("last_saved_unix", Time.get_unix_time_from_system()))
	var elapsed := clampi(int(Time.get_unix_time_from_system()) - last_saved_unix, 0, MAX_OFFLINE_SECONDS)
	var reward: int = int(elapsed / 60.0) * (1 + int(research_ranks.get("soul_alchemy", 0) / 3))
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
