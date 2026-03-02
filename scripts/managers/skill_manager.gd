extends Node
## SkillManager — Skill unlocking, requirement checking, modifier aggregation.
## Reads skill definitions from DataManager (skills.json).
## Modifiers feed into PlayerManager.get_effective_stat() alongside item modifiers.

signal skill_unlocked(player_id: int, skill_id: String)

# player_id → Array[String] of unlocked skill IDs (mirrors PlayerManager._player_data.unlocked_skills)
var _modifier_cache: Dictionary = {}  # player_id → Dictionary of aggregated modifiers


# --- Unlocking ---

func can_unlock_skill(player_id: int, skill_id: String) -> bool:
	var skill_data: Dictionary = DataManager.get_skill(skill_id)
	if skill_data.is_empty():
		return false

	# Already unlocked?
	if is_skill_unlocked(player_id, skill_id):
		return false

	# Has skill points?
	if PlayerManager.get_skill_points(player_id) <= 0:
		return false

	# Requirements met?
	var requirements: Array = skill_data.get("requirements", [])
	for req_id in requirements:
		if not is_skill_unlocked(player_id, req_id):
			return false

	return true


func unlock_skill(player_id: int, skill_id: String) -> bool:
	if not can_unlock_skill(player_id, skill_id):
		return false

	# Deduct skill point
	PlayerManager.deduct_skill_point(player_id)

	# Add to unlocked list
	var unlocked: Array = PlayerManager.get_unlocked_skills(player_id)
	unlocked.append(skill_id)
	PlayerManager.set_unlocked_skills(player_id, unlocked)

	_recalculate_modifiers(player_id)

	skill_unlocked.emit(player_id, skill_id)
	PlayerManager.stats_changed.emit(player_id)

	var skill_data: Dictionary = DataManager.get_skill(skill_id)
	print("SkillManager: Player %d unlocked '%s'" % [player_id, skill_data.get("display_name", skill_id)])
	return true


func is_skill_unlocked(player_id: int, skill_id: String) -> bool:
	return PlayerManager.get_unlocked_skills(player_id).has(skill_id)


# --- Modifier Aggregation ---

func get_skill_modifiers(player_id: int) -> Dictionary:
	if not _modifier_cache.has(player_id):
		_recalculate_modifiers(player_id)
	return _modifier_cache.get(player_id, {})


func _recalculate_modifiers(player_id: int) -> void:
	var mods: Dictionary = {}
	var unlocked: Array = PlayerManager.get_unlocked_skills(player_id)

	for skill_id in unlocked:
		var skill_data: Dictionary = DataManager.get_skill(skill_id)
		if skill_data.is_empty():
			continue

		var effects: Array = skill_data.get("effects", [])
		for effect in effects:
			var stat: String = effect.get("stat", "")
			var mod_type: String = effect.get("modifier_type", "")
			var value: float = float(effect.get("value", 0))

			if stat == "" or mod_type == "":
				continue

			var key := stat + "_" + mod_type  # e.g. "damage_percent"
			mods[key] = mods.get(key, 0.0) + value

	_modifier_cache[player_id] = mods


func invalidate_cache(player_id: int) -> void:
	_modifier_cache.erase(player_id)


# --- Queries ---

func get_unlocked_count(player_id: int) -> int:
	return PlayerManager.get_unlocked_skills(player_id).size()


func get_available_skills(player_id: int) -> Array:
	## Returns all skills the player can currently unlock.
	var available: Array = []
	for skill in DataManager.get_all_skills():
		var sid: String = skill.get("id", "")
		if can_unlock_skill(player_id, sid):
			available.append(skill)
	return available
