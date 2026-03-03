extends Node
## CombatManager — Enemy spawning, damage calculation, loot drops.
## All combat logic runs host-side.
## Damage formula: BaseDamage × CritMultiplier, then defender dodge roll.

const ENEMY_SCENE_PATH := "res://scenes/entities/Enemy.tscn"
const LOOT_SCENE_PATH := "res://scenes/entities/LootPickup.tscn"

const CRIT_MULTIPLIER := 2.0
const BASE_ITEM_DROP_CHANCE := 0.30  # 30% chance an enemy drops an item

signal enemy_spawned(enemy_node: Node)
signal enemy_died(enemy_id: String, position: Vector2)
signal damage_dealt(target: Node, amount: float, is_crit: bool, is_dodge: bool)
signal loot_dropped(item_id: String, position: Vector2)

var _active_enemies: Array[Node] = []


# --- Damage Calculation ---

func apply_damage(attacker: Node, target: Node, base_damage: float) -> Dictionary:
	var result := {"amount": 0.0, "is_crit": false, "is_dodge": false}

	# Get attacker crit chance
	var attacker_crit: float = _get_stat(attacker, "crit_chance")
	# Get defender dodge chance
	var defender_dodge: float = _get_stat(target, "dodge_chance")

	# Dodge roll
	if randf() < defender_dodge:
		result["is_dodge"] = true
		damage_dealt.emit(target, 0.0, false, true)
		return result

	# Crit roll
	var final_damage: float = base_damage
	if randf() < attacker_crit:
		final_damage *= CRIT_MULTIPLIER
		result["is_crit"] = true

	result["amount"] = final_damage

	# Apply to target's HealthComponent
	var health_comp = target.get_node_or_null("HealthComponent")
	if health_comp and health_comp.has_method("take_damage"):
		health_comp.take_damage(final_damage)

	damage_dealt.emit(target, final_damage, result["is_crit"], false)
	return result


func _get_stat(node: Node, stat: String) -> float:
	# Player: read from PlayerManager
	if node.has_method("set_player_id") and node.get("player_id") != null:
		return PlayerManager.get_effective_stat(node.player_id, stat)
	# Enemy: read from scaled stats
	if node.has_method("get_stat"):
		return node.get_stat(stat)
	return 0.0


# --- Enemy Spawning ---

func spawn_enemy(enemy_id: String, position: Vector2, scaling: Dictionary = {}, parent: Node = null) -> Node:
	var packed := load(ENEMY_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("CombatManager: Failed to load Enemy scene")
		return null

	var enemy_data: Dictionary = DataManager.get_enemy(enemy_id)
	if enemy_data.is_empty():
		push_error("CombatManager: Unknown enemy_id '%s'" % enemy_id)
		return null

	var enemy_node := packed.instantiate()
	enemy_node.name = "Enemy_%s_%d" % [enemy_id, _active_enemies.size()]

	if enemy_node.has_method("initialize"):
		enemy_node.initialize(enemy_data, scaling)

	# Add to scene
	var target_parent: Node = parent
	if target_parent == null:
		target_parent = _get_scene_parent()
	target_parent.add_child(enemy_node)
	enemy_node.global_position = position

	_active_enemies.append(enemy_node)

	# Connect death signal
	var health_comp = enemy_node.get_node_or_null("HealthComponent")
	if health_comp:
		health_comp.died.connect(_on_enemy_died.bind(enemy_node, enemy_data))

	enemy_spawned.emit(enemy_node)
	return enemy_node


func spawn_wave(enemy_groups: Array, room_center: Vector2, scaling: Dictionary = {}, parent: Node = null) -> void:
	var offset_index := 0
	var total_enemies := 0
	for group in enemy_groups:
		var count_mult: float = scaling.get("enemy_count_multiplier", 1.0)
		total_enemies += maxi(1, roundi(group.get("count", 1) * count_mult))

	for group in enemy_groups:
		var eid: String = group.get("enemy_id", "")
		var count: int = group.get("count", 1)
		var count_mult: float = scaling.get("enemy_count_multiplier", 1.0)
		var scaled_count: int = maxi(1, roundi(count * count_mult))

		for i in range(scaled_count):
			var angle: float = (offset_index * TAU) / maxf(1.0, float(total_enemies))
			var radius: float = 100.0 + randf() * 50.0
			var pos := room_center + Vector2(cos(angle), sin(angle)) * radius
			spawn_enemy(eid, pos, scaling, parent)
			offset_index += 1


# --- Enemy Death ---

func _on_enemy_died(enemy_node: Node, enemy_data: Dictionary) -> void:
	var pos: Vector2 = enemy_node.global_position
	var eid: String = enemy_data.get("id", "")

	# Award XP to all active players
	var xp_reward: int = enemy_data.get("xp_reward", 0)
	if xp_reward > 0:
		var player_ids := MultiplayerManager.get_all_player_ids()
		for pid in player_ids:
			PlayerManager.add_xp(pid, xp_reward)

	# Drop money
	var money_drop: Dictionary = enemy_data.get("money_drop", {})
	var min_money: int = money_drop.get("min", 0)
	var max_money: int = money_drop.get("max", 0)
	if max_money > 0:
		var amount: int = randi_range(min_money, max_money)
		_spawn_money_pickup(pos + Vector2(randf_range(-15, 15), randf_range(-15, 15)), amount)

	# Drop loot item (random chance)
	var loot_table_id: String = enemy_data.get("loot_table_id", "")
	if loot_table_id != "" and randf() < BASE_ITEM_DROP_CHANCE:
		drop_loot(loot_table_id, pos + Vector2(randf_range(-20, 20), randf_range(-20, 20)))

	_active_enemies.erase(enemy_node)
	enemy_died.emit(eid, pos)

	if enemy_node.has_method("play_death"):
		enemy_node.play_death()
	else:
		enemy_node.queue_free()


# --- Loot Resolution ---

func drop_loot(loot_table_id: String, position: Vector2, _quality_multiplier: float = 1.0) -> void:
	var table: Dictionary = DataManager.get_loot_table(loot_table_id)
	if table.is_empty():
		return

	var drops: Array = table.get("drops", [])
	if drops.is_empty():
		return

	var item_id := resolve_weighted_drop(drops)
	if item_id == "":
		return

	_spawn_item_pickup(position, item_id)
	loot_dropped.emit(item_id, position)


func resolve_weighted_drop(drops: Array) -> String:
	var total_weight: float = 0.0
	for drop in drops:
		total_weight += float(drop.get("weight", 0))
	if total_weight <= 0.0:
		return ""

	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	for drop in drops:
		cumulative += float(drop.get("weight", 0))
		if roll <= cumulative:
			return drop.get("item_id", "")

	return drops[drops.size() - 1].get("item_id", "")


# --- Pickup Spawning ---

func _spawn_item_pickup(position: Vector2, item_id: String) -> void:
	var packed := load(LOOT_SCENE_PATH) as PackedScene
	if packed == null:
		return
	var pickup := packed.instantiate()
	if pickup.has_method("setup_item"):
		pickup.setup_item(item_id)
	var target_parent := _get_scene_parent()
	target_parent.add_child(pickup)
	pickup.global_position = position


func _spawn_money_pickup(position: Vector2, amount: int) -> void:
	var packed := load(LOOT_SCENE_PATH) as PackedScene
	if packed == null:
		return
	var pickup := packed.instantiate()
	if pickup.has_method("setup_money"):
		pickup.setup_money(amount)
	var target_parent := _get_scene_parent()
	target_parent.add_child(pickup)
	pickup.global_position = position


func _get_scene_parent() -> Node:
	var sm = get_node_or_null("/root/Main/SceneManager")
	if sm and sm.get_current_scene():
		return sm.get_current_scene()
	return get_tree().current_scene


# --- Utility ---

func get_active_enemy_count() -> int:
	_active_enemies = _active_enemies.filter(func(e): return is_instance_valid(e))
	return _active_enemies.size()


func clear_all_enemies() -> void:
	for enemy in _active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_active_enemies.clear()
