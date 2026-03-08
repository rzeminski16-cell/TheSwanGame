extends CanvasModulate
## VisualEffects — Day/night tint overlay and screen shake.
## Attached under UIManager or directly in scenes.
## Reads TimeManager to adjust ambient color.

var _base_color := Color(1.0, 1.0, 1.0, 1.0)
var _shake_offset := Vector2.ZERO
var _shake_intensity: float = 0.0
var _shake_decay: float = 8.0
var _original_offset := Vector2.ZERO

# Day/night color palette
const DAY_COLOR := Color(1.0, 1.0, 0.95)
const EVENING_COLOR := Color(1.0, 0.85, 0.7)
const NIGHT_COLOR := Color(0.5, 0.5, 0.8)
const MORNING_COLOR := Color(0.95, 0.9, 0.85)


func _ready() -> void:
	color = DAY_COLOR


func _process(delta: float) -> void:
	_update_day_night()
	_update_shake(delta)


func _update_day_night() -> void:
	var time_of_day: float = GameState.current_time_of_day

	# 0.0-0.1 morning, 0.1-0.4 day, 0.4-0.5 evening, 0.5-1.0 night
	if time_of_day < 0.1:
		color = MORNING_COLOR.lerp(DAY_COLOR, time_of_day / 0.1)
	elif time_of_day < 0.4:
		color = DAY_COLOR
	elif time_of_day < 0.5:
		var t := (time_of_day - 0.4) / 0.1
		color = DAY_COLOR.lerp(EVENING_COLOR, t)
	elif time_of_day < 0.6:
		var t := (time_of_day - 0.5) / 0.1
		color = EVENING_COLOR.lerp(NIGHT_COLOR, t)
	elif time_of_day < 0.95:
		color = NIGHT_COLOR
	else:
		var t := (time_of_day - 0.95) / 0.05
		color = NIGHT_COLOR.lerp(MORNING_COLOR, t)


func _update_shake(delta: float) -> void:
	if _shake_intensity > 0.01:
		_shake_intensity = lerpf(_shake_intensity, 0.0, _shake_decay * delta)
		_shake_offset = Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)
		# Apply shake to the active camera
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
