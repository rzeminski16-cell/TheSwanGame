extends Node
## InventoryManager — Player inventories and passive item effects.
## Full implementation in Phase 2.

signal item_added(player_id: int, item_id: String)
signal item_removed(player_id: int, item_id: String)


func add_item(_player_id: int, _item_id: String) -> bool:
	# Phase 2: Add to inventory, recalculate passives
	push_warning("InventoryManager.add_item() not yet implemented")
	return false


func remove_item(_player_id: int, _item_id: String) -> bool:
	# Phase 2: Remove from inventory, recalculate passives
	push_warning("InventoryManager.remove_item() not yet implemented")
	return false


func get_inventory(_player_id: int) -> Array:
	return []


func get_passive_modifiers(_player_id: int) -> Dictionary:
	# Phase 2: Calculate total stat modifiers from all items
	return {}


func check_capacity(_player_id: int) -> bool:
	return true
