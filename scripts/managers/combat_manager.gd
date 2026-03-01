extends Node
## CombatManager — Enemy spawning, damage, loot.
## All combat logic runs host-side.
## Full implementation in Phase 2.

signal enemy_spawned(enemy_node: Node)
signal enemy_died(enemy_id: String, position: Vector2)
signal damage_dealt(target: Node, amount: float, is_crit: bool)
signal loot_dropped(item_id: String, position: Vector2)


func spawn_enemy(_enemy_id: String, _position: Vector2, _scaling: Dictionary = {}) -> Node:
	# Phase 2: Instantiate enemy, apply stats + scaling
	push_warning("CombatManager.spawn_enemy() not yet implemented")
	return null


func spawn_wave(_enemy_groups: Array, _room_center: Vector2, _scaling: Dictionary = {}) -> void:
	# Phase 2: Spawn a group of enemies
	push_warning("CombatManager.spawn_wave() not yet implemented")


func apply_damage(_attacker: Node, _target: Node, _base_damage: float) -> float:
	# Phase 2: Calculate damage with crit/dodge
	# DamageDealt = BaseDamage * (1 + Modifiers)
	push_warning("CombatManager.apply_damage() not yet implemented")
	return 0.0


func drop_loot(_loot_table_id: String, _position: Vector2, _quality_multiplier: float = 1.0) -> void:
	# Phase 2: Resolve loot table, spawn pickup
	push_warning("CombatManager.drop_loot() not yet implemented")
