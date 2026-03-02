extends PanelContainer
## PauseMenu — Simple pause screen with resume button.
## Toggled with ESC. Pauses the game tree.

signal resumed()


func _ready() -> void:
	custom_minimum_size = Vector2(300, 200)
	set_anchors_preset(Control.PRESET_CENTER)
	_build_ui()


func _build_ui() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.05, 0.08, 0.95)
	bg.border_color = Color(0.5, 0.5, 0.6)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(10)
	bg.set_content_margin_all(20)
	add_theme_stylebox_override("panel", bg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)

	var title := Label.new()
	title.text = "PAUSED"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var resume_btn := Button.new()
	resume_btn.text = "Resume"
	resume_btn.custom_minimum_size = Vector2(200, 40)
	resume_btn.pressed.connect(_on_resume)
	vbox.add_child(resume_btn)

	var hint := Label.new()
	hint.text = "Press ESC to resume"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)


func _on_resume() -> void:
	resumed.emit()
