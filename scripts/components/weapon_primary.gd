extends Node2D
## WeaponPrimary — Auto-fires projectiles toward mouse at attack_speed rate.
## Damage value comes from PlayerManager. Projectiles are Area2D.

const PROJECTILE_SCENE_PATH := "res://scenes/entities/Projectile.tscn"

var _player_id: int = 1
var _attack_timer: float = 0.0
var _enabled: bool = true


func _ready() -> void:
	# Get player_id from parent
	var parent := get_parent()
	if parent and parent.has_method("set_player_id"):
		_player_id = parent.player_id


func _process(delta: float) -> void:
	if not _enabled:
		return

	_attack_timer = maxf(0.0, _attack_timer - delta)

	# Auto-fire when left mouse is held
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and _attack_timer <= 0.0:
		_fire()


func _fire() -> void:
	var attack_speed: float = PlayerManager.get_effective_stat(_player_id, "attack_speed")
	_attack_timer = 1.0 / maxf(0.1, attack_speed)

	var packed := load(PROJECTILE_SCENE_PATH) as PackedScene
	if packed == null:
		return

	var proj := packed.instantiate()

	# Direction toward mouse
	var mouse_pos := get_global_mouse_position()
	var dir := (mouse_pos - global_position).normalized()
	var damage: float = PlayerManager.get_effective_stat(_player_id, "damage")
	var player_node = PlayerManager.get_player_node(_player_id)

	if proj.has_method("setup"):
		proj.setup(dir, damage, player_node, "player")

	# Add to scene (not as child of player, so it persists if player moves)
	var scene_root := get_tree().current_scene
	if scene_root:
		scene_root.add_child(proj)
		proj.global_position = global_position


func set_enabled(enabled: bool) -> void:
	_enabled = enabled
