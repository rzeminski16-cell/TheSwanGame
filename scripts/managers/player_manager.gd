extends Node
## PlayerManager — Player spawning, stat computation, XP, leveling.
## All stats are data-driven from global_config.json.
## Stat formula: EffectiveStat = (Base + FlatBonuses) × (1 + PercentBonuses)
## Percentage stats (crit/dodge) use soft caps.

const PLAYER_SCENE_PATH := "res://scenes/entities/Player.tscn"

signal player_spawned(player_id: int)
signal player_leveled_up(player_id: int, new_level: int)
signal stats_changed(player_id: int)

# Per-player data: player_id → Dictionary
var _player_data: Dictionary = {}
# Per-player node reference: player_id → Node
var _player_nodes: Dictionary = {}


# --- Spawning ---

func spawn_player(player_id: int, parent: Node = null) -> Node:
	var packed := load(PLAYER_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("PlayerManager: Failed to load Player scene")
		return null

	var player_node := packed.instantiate()
	player_node.name = "Player_%d" % player_id

	if player_node.has_method("set_player_id"):
		player_node.set_player_id(player_id)

	# Initialize player data if not already tracked
	if not _player_data.has(player_id):
		_init_player_data(player_id)

	# Add to parent or current scene
	if parent != null:
		parent.add_child(player_node)
	else:
		var scene_manager = get_node_or_null("/root/Main/SceneManager")
		if scene_manager and scene_manager.get_current_scene():
			scene_manager.get_current_scene().add_child(player_node)
		else:
			get_tree().current_scene.add_child(player_node)

	_player_nodes[player_id] = player_node

	# Initialize health/stamina components with computed stats
	_apply_stats_to_node(player_id)

	player_spawned.emit(player_id)
	print("PlayerManager: Spawned player %d" % player_id)
	return player_node


func _init_player_data(player_id: int) -> void:
	_player_data[player_id] = {
		"level": 1,
		"xp": 0,
		"skill_points": 0,
		"unlocked_skills": [],
	}


func get_player_node(player_id: int) -> Node:
	var node = _player_nodes.get(player_id)
	if not is_instance_valid(node):
		_player_nodes.erase(player_id)
		return null
	return node


func has_player(player_id: int) -> bool:
	return _player_data.has(player_id)


# --- XP / Leveling ---

func add_xp(player_id: int, amount: int) -> void:
	if not _player_data.has(player_id):
		_init_player_data(player_id)

	var data := _player_data[player_id] as Dictionary
	var max_level: int = DataManager.get_config_value("max_player_level_demo", 5)

	if data["level"] >= max_level:
		return  # Already at cap

	data["xp"] += amount

	# Check for level ups (can level multiple times from one XP grant)
	while data["level"] < max_level:
		var xp_needed := get_xp_for_next_level(data["level"])
		if data["xp"] >= xp_needed:
			data["xp"] -= xp_needed
			data["level"] += 1
			data["skill_points"] += 1
			player_leveled_up.emit(player_id, data["level"])
			print("PlayerManager: Player %d leveled up to %d!" % [player_id, data["level"]])
		else:
			break

	# Clamp XP at max level
	if data["level"] >= max_level:
		data["xp"] = 0

	_apply_stats_to_node(player_id)
	stats_changed.emit(player_id)


func get_xp_for_next_level(current_level: int) -> int:
	var base: float = DataManager.get_config_value("base_xp_per_level", 100)
	var exponent: float = DataManager.get_config_value("xp_curve_exponent", 1.5)
	return roundi(base * pow(current_level, exponent))


func get_level(player_id: int) -> int:
	if not _player_data.has(player_id):
		return 1
	return _player_data[player_id]["level"]


func get_xp(player_id: int) -> int:
	if not _player_data.has(player_id):
		return 0
	return _player_data[player_id]["xp"]


func get_skill_points(player_id: int) -> int:
	if not _player_data.has(player_id):
		return 0
	return _player_data[player_id]["skill_points"]


func get_unlocked_skills(player_id: int) -> Array:
	if not _player_data.has(player_id):
		return []
	return _player_data[player_id]["unlocked_skills"]


func deduct_skill_point(player_id: int) -> void:
	if not _player_data.has(player_id):
		return
	_player_data[player_id]["skill_points"] = maxi(0, _player_data[player_id]["skill_points"] - 1)


func set_unlocked_skills(player_id: int, skills: Array) -> void:
	if not _player_data.has(player_id):
		_init_player_data(player_id)
	_player_data[player_id]["unlocked_skills"] = skills


# --- Stat Computation ---

func get_stats(player_id: int) -> Dictionary:
	var base_stats: Dictionary = DataManager.get_config_value("player_base_stats", {}).duplicate()
	var result: Dictionary = {}
	for stat in base_stats:
		result[stat] = get_effective_stat(player_id, stat)
	return result


func get_effective_stat(player_id: int, stat: String) -> float:
	var base_stats: Dictionary = DataManager.get_config_value("player_base_stats", {})
	var base_value: float = float(base_stats.get(stat, 0))

	var level: int = get_level(player_id)
	var level_bonuses := _get_level_bonuses(stat, level)

	# Item modifiers from InventoryManager
	var item_mods: Dictionary = InventoryManager.get_passive_modifiers(player_id)

	# Skill modifiers from SkillManager
	var skill_mods: Dictionary = SkillManager.get_skill_modifiers(player_id)

	var flat_bonus: float = level_bonuses["flat"]
	flat_bonus += float(item_mods.get(stat + "_flat", 0))
	flat_bonus += float(skill_mods.get(stat + "_flat", 0))

	var percent_bonus: float = level_bonuses["percent"]
	percent_bonus += float(item_mods.get(stat + "_percent", 0))
	percent_bonus += float(skill_mods.get(stat + "_percent", 0))

	var raw_value: float = (base_value + flat_bonus) * (1.0 + percent_bonus)

	# Apply soft caps for percentage stats
	if stat in ["crit_chance", "dodge_chance"]:
		raw_value = _apply_soft_cap(stat, raw_value)

	return raw_value


func _get_level_bonuses(stat: String, level: int) -> Dictionary:
	var bonuses: Dictionary = DataManager.get_config_value("level_up_bonuses", {})
	var levels_gained: int = level - 1  # Level 1 = no bonus

	var flat: float = 0.0
	var percent: float = 0.0

	# Check for flat bonus (e.g. "health": 5)
	if bonuses.has(stat):
		flat = float(bonuses[stat]) * levels_gained

	# Check for percent bonus (e.g. "damage_percent": 0.02)
	var percent_key := stat + "_percent"
	if bonuses.has(percent_key):
		percent = float(bonuses[percent_key]) * levels_gained

	return {"flat": flat, "percent": percent}


func _apply_soft_cap(stat: String, raw_value: float) -> float:
	var soft_caps: Dictionary = DataManager.get_config_value("soft_caps", {})
	if not soft_caps.has(stat):
		return raw_value

	var cap_data: Dictionary = soft_caps[stat]
	var cap_max: float = float(cap_data.get("max", 1.0))
	var scaling: float = float(cap_data.get("scaling_factor", 0.08))

	# Soft cap formula: capped = max × (1 - e^(-raw / scaling_factor))
	var capped: float = cap_max * (1.0 - exp(-raw_value / scaling))
	return capped


# --- Apply stats to player node ---

func _apply_stats_to_node(player_id: int) -> void:
	var node = _player_nodes.get(player_id)
	if node == null:
		return

	var stats := get_stats(player_id)

	# Update HealthComponent
	var health_comp = node.get_node_or_null("HealthComponent")
	if health_comp and health_comp.has_method("set_max_health"):
		health_comp.set_max_health(stats.get("health", 100))

	# Update StaminaComponent
	var stamina_comp = node.get_node_or_null("StaminaComponent")
	if stamina_comp and stamina_comp.has_method("set_max_stamina"):
		stamina_comp.set_max_stamina(stats.get("stamina", 100))


# --- Save/Load helpers (used by SaveManager in Phase 6) ---

func get_save_data(player_id: int) -> Dictionary:
	if not _player_data.has(player_id):
		return {}
	return _player_data[player_id].duplicate(true)


func load_save_data(player_id: int, data: Dictionary) -> void:
	_player_data[player_id] = data.duplicate(true)
	_apply_stats_to_node(player_id)
	stats_changed.emit(player_id)


func reset_player(player_id: int) -> void:
	_init_player_data(player_id)
	_apply_stats_to_node(player_id)
	stats_changed.emit(player_id)
