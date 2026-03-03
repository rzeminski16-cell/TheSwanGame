extends CanvasLayer
## DebugOverlay — Real-time stat display for development.
## Toggle with F4.

@onready var label: Label = $Panel/Label

var _visible := true
var _player_id: int = 1


func _ready() -> void:
	layer = 110  # Above UIManager


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug_overlay"):
		_visible = !_visible
		visible = _visible


func _process(_delta: float) -> void:
	if not _visible or label == null:
		return

	var level := PlayerManager.get_level(_player_id)
	var xp := PlayerManager.get_xp(_player_id)
	var max_level: int = DataManager.get_config_value("max_player_level_demo", 5)
	var xp_needed: String
	if level >= max_level:
		xp_needed = "MAX"
	else:
		xp_needed = str(PlayerManager.get_xp_for_next_level(level))

	var stats := PlayerManager.get_stats(_player_id)
	var sp := PlayerManager.get_skill_points(_player_id)

	var health_comp: HealthComponent = null
	var stamina_comp: StaminaComponent = null
	var player_node = PlayerManager.get_player_node(_player_id)
	if player_node:
		health_comp = player_node.get_node_or_null("HealthComponent")
		stamina_comp = player_node.get_node_or_null("StaminaComponent")

	var hp_cur := health_comp.current_health if health_comp else 0.0
	var hp_max := health_comp.max_health if health_comp else 0.0
	var st_cur := stamina_comp.current_stamina if stamina_comp else 0.0
	var st_max := stamina_comp.max_stamina if stamina_comp else 0.0

	label.text = "=== DEBUG (F4) ===\n"
	label.text += "Level: %d  |  XP: %d / %s  |  SP: %d\n" % [level, xp, xp_needed, sp]
	label.text += "Health: %.0f / %.0f\n" % [hp_cur, hp_max]
	label.text += "Stamina: %.0f / %.0f\n" % [st_cur, st_max]
	label.text += "---\n"
	label.text += "Damage: %.1f\n" % stats.get("damage", 0)
	label.text += "Attack Speed: %.2f\n" % stats.get("attack_speed", 0)
	label.text += "Move Speed: %.1f\n" % stats.get("move_speed", 0)
	label.text += "Crit Chance: %.1f%%\n" % (stats.get("crit_chance", 0) * 100)
	label.text += "Dodge Chance: %.1f%%\n" % (stats.get("dodge_chance", 0) * 100)
	label.text += "---\n"
	label.text += "Money: %d\n" % EconomyManager.get_money(_player_id)
	label.text += "Items: %d\n" % InventoryManager.get_inventory_count(_player_id)
	label.text += "Enemies: %d\n" % CombatManager.get_active_enemy_count()
