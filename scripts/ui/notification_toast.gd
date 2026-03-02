extends PanelContainer
## NotificationToast — Short-lived message that slides in and fades out.
## Spawned by UIManager.show_notification().

var _label: Label


func setup(text: String, duration: float = 2.0) -> void:
	_label = Label.new()
	_label.text = text
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style.border_color = Color(0.4, 0.4, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	add_theme_stylebox_override("panel", style)

	add_child(_label)

	# Animate
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.tween_interval(duration)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
