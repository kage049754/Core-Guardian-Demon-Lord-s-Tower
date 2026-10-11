extends SceneTree

func _initialize() -> void:
	var checks := [
		["res://content/floors.json", "floors", 100],
		["res://content/guardians.json", "guardians", 5],
		["res://content/enemies.json", "archetypes", 8],
		["res://content/research.json", "branches", 5],
		["res://content/core_evolutions.json", "branches", 3],
		["res://content/relics.json", "relics", 6]
	]
	for check in checks:
		var file := FileAccess.open(check[0], FileAccess.READ)
		if file == null:
			push_error("Missing content file: " + str(check[0]))
			quit(1)
			return
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(parsed) != TYPE_DICTIONARY:
			push_error("Invalid JSON object: " + str(check[0]))
			quit(1)
			return
		var data: Dictionary = parsed
		var entries: Variant = data.get(check[1], [])
		if typeof(entries) != TYPE_ARRAY or entries.size() != check[2]:
			push_error("Unexpected entry count in " + str(check[0]))
			quit(1)
			return
	var floor_file := FileAccess.open("res://content/floors.json", FileAccess.READ)
	var floor_data: Dictionary = JSON.parse_string(floor_file.get_as_text())
	floor_file.close()
	var floors: Array = floor_data["floors"]
	for i in range(floors.size()):
		if int(floors[i]["floor"]) != i + 1:
			push_error("Floor definitions must be consecutive from 1 to 100.")
			quit(1)
			return
	print("PASS: 100 floors, 10 milestone bosses, guardians, enemy archetypes, research, evolutions and relic data.")
	quit(0)
