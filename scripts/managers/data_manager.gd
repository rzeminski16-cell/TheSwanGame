extends Node
## DataManager — Loads all JSON data files at startup.
## Access data through typed getter functions.
## This is the single source of truth for all game definitions.

const DATA_PATH := "res://data/"

var _config: Dictionary = {}
var _enemies: Dictionary = {}       # id → enemy dict
var _items: Dictionary = {}         # id → item dict
var _skills: Dictionary = {}        # id → skill dict
var _loot_tables: Dictionary = {}   # id → loot table dict
var _dungeons: Dictionary = {}      # id → dungeon dict
var _missions: Dictionary = {}      # id → mission dict
var _delivery_jobs: Array = []

var _load_errors: Array[String] = []


func _ready() -> void:
	load_all()
	if _load_errors.size() > 0:
		for err in _load_errors:
			push_error("DataManager: " + err)
		push_error("DataManager: %d error(s) during data load." % _load_errors.size())
	else:
		print("DataManager: All data loaded successfully.")


func load_all() -> void:
	_load_errors.clear()
	_load_config()
	_load_enemies()
	_load_items()
	_load_skills()
	_load_loot_tables()
	_load_dungeons()
	_load_missions()
	_load_delivery_jobs()
	_validate_references()


# --- Config ---

func get_config() -> Dictionary:
	return _config


func get_config_value(key: String, default_value = null):
	return _config.get(key, default_value)


# --- Enemies ---

func get_enemy(id: String) -> Dictionary:
	if not _enemies.has(id):
		push_warning("DataManager: Enemy '%s' not found." % id)
		return {}
	return _enemies[id]


func get_all_enemies() -> Array:
	return _enemies.values()


# --- Items ---

func get_item(id: String) -> Dictionary:
	if not _items.has(id):
		push_warning("DataManager: Item '%s' not found." % id)
		return {}
	return _items[id]


func get_all_items() -> Array:
	return _items.values()


# --- Skills ---

func get_skill(id: String) -> Dictionary:
	if not _skills.has(id):
		push_warning("DataManager: Skill '%s' not found." % id)
		return {}
	return _skills[id]


func get_all_skills() -> Array:
	return _skills.values()


func get_skills_by_category(category: String) -> Array:
	var result: Array = []
	for skill in _skills.values():
		if skill.get("category", "") == category:
			result.append(skill)
	return result


# --- Loot Tables ---

func get_loot_table(id: String) -> Dictionary:
	if not _loot_tables.has(id):
		push_warning("DataManager: Loot table '%s' not found." % id)
		return {}
	return _loot_tables[id]


# --- Dungeons ---

func get_dungeon(id: String) -> Dictionary:
	if not _dungeons.has(id):
		push_warning("DataManager: Dungeon '%s' not found." % id)
		return {}
	return _dungeons[id]


func get_all_dungeons() -> Array:
	return _dungeons.values()


# --- Missions ---

func get_mission(id: String) -> Dictionary:
	if not _missions.has(id):
		push_warning("DataManager: Mission '%s' not found." % id)
		return {}
	return _missions[id]


func get_all_missions() -> Array:
	return _missions.values()


# --- Delivery Jobs ---

func get_delivery_jobs() -> Array:
	return _delivery_jobs


# --- Internal Loaders ---

func _load_json(filename: String) -> Variant:
	var path := DATA_PATH + filename
	if not FileAccess.file_exists(path):
		_load_errors.append("File not found: " + path)
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_load_errors.append("Cannot open: " + path)
		return null
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var parse_result := json.parse(text)
	if parse_result != OK:
		_load_errors.append("JSON parse error in %s at line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	return json.data


func _index_by_id(array: Array) -> Dictionary:
	var indexed: Dictionary = {}
	for entry in array:
		var id = entry.get("id", "")
		if id == "":
			_load_errors.append("Entry missing 'id' field: %s" % str(entry))
			continue
		if indexed.has(id):
			_load_errors.append("Duplicate id: '%s'" % id)
		indexed[id] = entry
	return indexed


func _load_config() -> void:
	var data = _load_json("global_config.json")
	if data is Dictionary:
		_config = data
		print("DataManager: Loaded global_config.json")
	else:
		_load_errors.append("global_config.json must be a Dictionary")


func _load_enemies() -> void:
	var data = _load_json("enemies.json")
	if data is Dictionary and data.has("enemies"):
		_enemies = _index_by_id(data["enemies"])
		print("DataManager: Loaded %d enemies" % _enemies.size())
	else:
		_load_errors.append("enemies.json must contain 'enemies' array")


func _load_items() -> void:
	var data = _load_json("items.json")
	if data is Dictionary and data.has("items"):
		_items = _index_by_id(data["items"])
		print("DataManager: Loaded %d items" % _items.size())
	else:
		_load_errors.append("items.json must contain 'items' array")


func _load_skills() -> void:
	var data = _load_json("skills.json")
	if data is Dictionary and data.has("skills"):
		_skills = _index_by_id(data["skills"])
		print("DataManager: Loaded %d skills" % _skills.size())
	else:
		_load_errors.append("skills.json must contain 'skills' array")


func _load_loot_tables() -> void:
	var data = _load_json("loot_tables.json")
	if data is Dictionary and data.has("loot_tables"):
		_loot_tables = _index_by_id(data["loot_tables"])
		print("DataManager: Loaded %d loot tables" % _loot_tables.size())
	else:
		_load_errors.append("loot_tables.json must contain 'loot_tables' array")


func _load_dungeons() -> void:
	var data = _load_json("dungeons.json")
	if data is Dictionary and data.has("dungeons"):
		_dungeons = _index_by_id(data["dungeons"])
		print("DataManager: Loaded %d dungeons" % _dungeons.size())
	else:
		_load_errors.append("dungeons.json must contain 'dungeons' array")


func _load_missions() -> void:
	var data = _load_json("missions.json")
	if data is Dictionary and data.has("missions"):
		_missions = _index_by_id(data["missions"])
		print("DataManager: Loaded %d missions" % _missions.size())
	else:
		_load_errors.append("missions.json must contain 'missions' array")


func _load_delivery_jobs() -> void:
	var data = _load_json("delivery_jobs.json")
	if data is Dictionary and data.has("delivery_jobs"):
		_delivery_jobs = data["delivery_jobs"]
		print("DataManager: Loaded %d delivery jobs" % _delivery_jobs.size())
	else:
		_load_errors.append("delivery_jobs.json must contain 'delivery_jobs' array")


# --- Cross-Reference Validation ---

func _validate_references() -> void:
	# Validate enemy loot_table_id references
	for enemy in _enemies.values():
		var lt_id = enemy.get("loot_table_id", "")
		if lt_id != "" and not _loot_tables.has(lt_id):
			_load_errors.append("Enemy '%s' references missing loot table '%s'" % [enemy["id"], lt_id])

	# Validate loot table item_id references
	for table in _loot_tables.values():
		for drop in table.get("drops", []):
			var item_id = drop.get("item_id", "")
			if item_id != "" and not _items.has(item_id):
				_load_errors.append("Loot table '%s' references missing item '%s'" % [table["id"], item_id])

	# Validate dungeon enemy_id references
	for dungeon in _dungeons.values():
		for room in dungeon.get("rooms", []):
			if room.get("room_type") == "boss":
				var eid = room.get("enemy_id", "")
				if eid != "" and not _enemies.has(eid):
					_load_errors.append("Dungeon '%s' boss room references missing enemy '%s'" % [dungeon["id"], eid])
			for group in room.get("enemy_groups", []):
				var eid = group.get("enemy_id", "")
				if eid != "" and not _enemies.has(eid):
					_load_errors.append("Dungeon '%s' references missing enemy '%s'" % [dungeon["id"], eid])

	# Validate mission next_mission_id references
	for mission in _missions.values():
		var next_id = mission.get("next_mission_id")
		if next_id != null and next_id != "" and not _missions.has(next_id):
			_load_errors.append("Mission '%s' references missing next mission '%s'" % [mission["id"], next_id])

	# Validate skill requirement references
	for skill in _skills.values():
		for req_id in skill.get("requirements", []):
			if not _skills.has(req_id):
				_load_errors.append("Skill '%s' requires missing skill '%s'" % [skill["id"], req_id])

	if _load_errors.size() == 0:
		print("DataManager: All cross-references valid.")
