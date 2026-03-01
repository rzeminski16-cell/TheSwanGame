extends CanvasLayer
## UIManager — Manages UI layers and screens.
## Child of Main.tscn (not an autoload).
## Full implementation in Phase 3.

signal hud_toggled(visible: bool)
signal screen_opened(screen_name: String)
signal screen_closed(screen_name: String)


func _ready() -> void:
	# Set to high layer so UI renders on top
	layer = 100
	print("UIManager: Ready.")


func show_hud() -> void:
	# Phase 3: Show the HUD
	push_warning("UIManager.show_hud() not yet implemented")


func hide_hud() -> void:
	# Phase 3: Hide the HUD
	push_warning("UIManager.hide_hud() not yet implemented")


func toggle_inventory() -> void:
	# Phase 3: Toggle inventory screen
	push_warning("UIManager.toggle_inventory() not yet implemented")


func toggle_skill_tree() -> void:
	# Phase 3: Toggle skill tree screen
	push_warning("UIManager.toggle_skill_tree() not yet implemented")


func show_notification(_text: String, _duration: float = 2.0) -> void:
	# Phase 3: Show floating notification
	push_warning("UIManager.show_notification() not yet implemented")


func spawn_damage_popup(_position: Vector2, _amount: float, _is_crit: bool = false, _is_dodge: bool = false) -> void:
	# Phase 3: Spawn floating damage number
	push_warning("UIManager.spawn_damage_popup() not yet implemented")
