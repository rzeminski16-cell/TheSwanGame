extends Node2D
## DamagePopup — Floating damage number that rises and fades.
## Spawned in world space at target position.
## Red for normal, yellow for crit, white "DODGE" for dodge.

var _label: Label
var _amount: float = 0.0
var _is_crit: bool = false
var _is_dodge: bool = false


func setup(amount: float, is_crit: bool, is_dodge: bool) -> void:
	_amount = amount
	_is_crit = is_crit
	_is_dodge = is_dodge


func _ready() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	if _is_dodge:
		_label.text = "DODGE"
		_label.add_theme_font_size_override("font_size", 14)
		_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	elif _is_crit:
		_label.text = "%.0f!" % _amount
		_label.add_theme_font_size_override("font_size", 20)
		_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.1))
	else:
		_label.text = "%.0f" % _amount
		_label.add_theme_font_size_override("font_size", 14)
		_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))

	# Center the label
	_label.position = Vector2(-30, -15)
	_label.size = Vector2(60, 30)
	add_child(_label)

	# Random horizontal offset
	position.x += randf_range(-10, 10)

	# Animate: float up and fade
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 40.0, 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(_label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
