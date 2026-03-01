extends Node
## PlayerManager — Player spawning, stats, leveling.
## Full implementation in Phase 1.

signal player_spawned(player_id: int)
signal player_leveled_up(player_id: int, new_level: int)
signal stats_changed(player_id: int)


func spawn_player(_player_id: int) -> Node:
	# Phase 1: Instantiate Player.tscn, configure stats
	push_warning("PlayerManager.spawn_player() not yet implemented")
	return null


func get_stats(_player_id: int) -> Dictionary:
	# Phase 1: Return computed stats (base + level + items + skills)
	return DataManager.get_config().get("player_base_stats", {}).duplicate()


func add_xp(_player_id: int, _amount: int) -> void:
	# Phase 1: Add XP, check for level up
	push_warning("PlayerManager.add_xp() not yet implemented")


func get_level(_player_id: int) -> int:
	return 1


func get_xp(_player_id: int) -> int:
	return 0


func get_effective_stat(_player_id: int, _stat: String) -> float:
	# Phase 1: Base + level + items + skills, with soft caps
	var base_stats = DataManager.get_config().get("player_base_stats", {})
	return float(base_stats.get(_stat, 0))
