extends Node
## DungeonManager — Dungeon lifecycle, scaling, completion tracking.
## Full implementation in Phase 4.

signal dungeon_started(dungeon_id: String)
signal dungeon_completed(dungeon_id: String)
signal room_cleared(room_index: int)

var _completion_counts: Dictionary = {}  # dungeon_id → int


func start_dungeon(_dungeon_id: String) -> bool:
	# Phase 4: Load dungeon data, apply scaling, initialize rooms
	push_warning("DungeonManager.start_dungeon() not yet implemented")
	return false


func complete_dungeon(_dungeon_id: String) -> void:
	# Phase 4: Increment completion, update scaling, trigger rewards
	push_warning("DungeonManager.complete_dungeon() not yet implemented")


func get_completion_count(dungeon_id: String) -> int:
	return _completion_counts.get(dungeon_id, 0)


func get_scaling(dungeon_id: String) -> Dictionary:
	# Phase 4: Calculate all multipliers from completion count + config
	var count := get_completion_count(dungeon_id)
	var config := DataManager.get_config()
	return {
		"difficulty_multiplier": 1.0 + (count * config.get("dungeon_scaling_per_completion", 0.15)),
		"enemy_health_multiplier": 1.0 + (count * config.get("enemy_health_scaling", 0.12)),
		"enemy_damage_multiplier": 1.0 + (count * config.get("enemy_damage_scaling", 0.08)),
		"enemy_count_multiplier": 1.0 + (count * config.get("enemy_spawn_scaling", 0.10)),
		"loot_quality_multiplier": 1.0 + (count * config.get("loot_quality_scaling", 0.10)),
	}
