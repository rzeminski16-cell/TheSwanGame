extends Node
## InventoryManager — Player inventories and passive item effects.
## Tracks items per player and aggregates stat modifiers for PlayerManager.
## All item data comes from DataManager (items.json).

signal item_added(player_id: int, item_id: String)
signal item_removed(player_id: int, item_id: String)

# player_id → Array[String] of item IDs
var _inventories: Dictionary = {}
# player_id → Dictionary of aggregated stat modifiers (e.g. "damage_percent": 0.10)
var _modifier_cache: Dictionary = {}


# --- Item Management ---

func add_item(player_id: int, item_id: String) -> bool:
	var item_data: Dictionary = DataManager.get_item(item_id)
	if item_data.is_empty():
		push_warning("InventoryManager: Unknown item_id '%s'" % item_id)
		return false

	_ensure_player(player_id)
	_inventories[player_id].append(item_id)
	_recalculate_modifiers(player_id)

	item_added.emit(player_id, item_id)
	PlayerManager.stats_changed.emit(player_id)
	print("InventoryManager: Player %d picked up '%s'" % [player_id, item_data.get("display_name", item_id)])
	return true


func remove_item(player_id: int, item_id: String) -> bool:
	_ensure_player(player_id)
	var inv: Array = _inventories[player_id]
	var idx := inv.find(item_id)
	if idx == -1:
		return false

	inv.remove_at(idx)
	_recalculate_modifiers(player_id)

	item_removed.emit(player_id, item_id)
	PlayerManager.stats_changed.emit(player_id)
	return true


func remove_random_item(player_id: int) -> String:
	## Removes a random item from player inventory (used by death penalty).
	## Returns the removed item_id, or "" if inventory is empty.
	_ensure_player(player_id)
	var inv: Array = _inventories[player_id]
	if inv.is_empty():
		return ""

	var idx := randi() % inv.size()
	var item_id: String = inv[idx]
	inv.remove_at(idx)
	_recalculate_modifiers(player_id)

	item_removed.emit(player_id, item_id)
	PlayerManager.stats_changed.emit(player_id)
	print("InventoryManager: Player %d lost item '%s'" % [player_id, item_id])
	return item_id


# --- Queries ---

func get_inventory(player_id: int) -> Array:
	_ensure_player(player_id)
	return _inventories[player_id].duplicate()


func get_inventory_count(player_id: int) -> int:
	_ensure_player(player_id)
	return _inventories[player_id].size()


func has_item(player_id: int, item_id: String) -> bool:
	_ensure_player(player_id)
	return _inventories[player_id].has(item_id)


func get_passive_modifiers(player_id: int) -> Dictionary:
	## Returns aggregated stat modifiers from all held items.
	## Keys use format: "stat_modifierType" e.g. "damage_percent", "health_flat"
	## PlayerManager reads these in get_effective_stat().
	if not _modifier_cache.has(player_id):
		return {}
	return _modifier_cache[player_id]


func check_capacity(_player_id: int) -> bool:
	# No inventory limit defined in design docs — always has room
	return true


# --- Modifier Calculation ---

func _recalculate_modifiers(player_id: int) -> void:
	var mods: Dictionary = {}

	var inv: Array = _inventories.get(player_id, [])
	for item_id in inv:
		var item_data: Dictionary = DataManager.get_item(item_id)
		if item_data.is_empty():
			continue

		var effects: Array = item_data.get("effects", [])
		for effect in effects:
			var stat: String = effect.get("stat", "")
			var mod_type: String = effect.get("modifier_type", "")
			var value: float = float(effect.get("value", 0))

			if stat == "" or mod_type == "":
				continue

			var key := stat + "_" + mod_type  # e.g. "damage_percent"
			mods[key] = mods.get(key, 0.0) + value

	_modifier_cache[player_id] = mods


# --- Save/Load helpers (used by SaveManager in Phase 6) ---

func get_save_data(player_id: int) -> Array:
	return get_inventory(player_id)


func load_save_data(player_id: int, items: Array) -> void:
	_inventories[player_id] = items.duplicate()
	_recalculate_modifiers(player_id)
	PlayerManager.stats_changed.emit(player_id)


func clear_inventory(player_id: int) -> void:
	_inventories[player_id] = []
	_modifier_cache[player_id] = {}
	PlayerManager.stats_changed.emit(player_id)


# --- Internal ---

func _ensure_player(player_id: int) -> void:
	if not _inventories.has(player_id):
		_inventories[player_id] = []
		_modifier_cache[player_id] = {}
