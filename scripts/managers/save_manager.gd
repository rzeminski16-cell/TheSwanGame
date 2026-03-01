extends Node
## SaveManager — Serialization and persistence.
## Full implementation in Phase 6.

const SAVE_PATH := "user://save_data.json"


func save_game() -> bool:
	# Phase 6: Collect state from all managers, serialize to JSON
	push_warning("SaveManager.save_game() not yet implemented")
	return false


func load_game() -> bool:
	# Phase 6: Read JSON, distribute to all managers
	push_warning("SaveManager.load_game() not yet implemented")
	return false


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
