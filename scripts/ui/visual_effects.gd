extends Node
## VisualEffects — Screen shake, hit flash, and day/night tinting.
## Lives under UIManager. Screen shake manipulates the active Camera2D.

var _shake_offset := Vector2.ZERO
var _shake_intensity: float = 0.0
var _shake_decay: float = 8.0
var _original_offset := Vector2.ZERO

# Day/night color palette
const DAY_COLOR := Color(1.0, 1.0, 0.95)
const EVENING_COLOR := Color(1.0, 0.85, 0.7)
const NIGHT_COLOR := Color(0.5, 0.5, 0.8)
const MORNING_COLOR := Color(0.95, 0.9, 0.85)


func _process(delta: float) -> void:
	_update_shake(delta)


func _update_shake(delta: float) -> void:
	if _shake_intensity > 0.01:
		_shake_intensity = lerpf(_shake_intensity, 0.0, _shake_decay * delta)
		_shake_offset = Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)
		var cam := get_viewport().get_camera_2d()
		if cam:
			cam.offset = _original_offset + _shake_offset
	elif _shake_offset != Vector2.ZERO:
		_shake_offset = Vector2.ZERO
		var cam := get_viewport().get_camera_2d()
		if cam:
			cam.offset = _original_offset


func screen_shake(intensity: float = 5.0, decay: float = 8.0) -> void:
	## Trigger a screen shake effect.
	_shake_intensity = intensity
	_shake_decay = decay
	var cam := get_viewport().get_camera_2d()
	if cam:
		_original_offset = cam.offset


func hit_flash(node: Node2D, flash_color: Color = Color.WHITE, duration: float = 0.1) -> void:
	## Flash a node white briefly (hit feedback).
	if not is_instance_valid(node):
		return
	var original := node.modulate
	node.modulate = flash_color
	var tween := create_tween()
	tween.tween_property(node, "modulate", original, duration)
