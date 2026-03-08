extends PanelContainer
## PauseMenu — Pause screen with Resume, Save, Switch Character, Load, Main Menu.
## Toggled with ESC. Pauses the game tree.

signal resumed()
signal save_requested()
signal switch_character_requested()
signal load_requested()
signal main_menu_requested()

var _save_btn: Button
var _load_btn: Button
var _switch_btn: Button


func _ready() -> void:
	custom_minimum_size = Vector2(300, 400)
	size = Vector2(300, 400)
	var vp_size := get_viewport_rect().size
	position = Vector2((vp_size.x - 300) / 2.0, (vp_size.y - 400) / 2.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
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
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)

	var title := Label.new()
	title.text = "PAUSED"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# Resume
	var resume_btn := Button.new()
	resume_btn.text = "Resume"
	resume_btn.custom_minimum_size = Vector2(200, 38)
	resume_btn.pressed.connect(_on_resume)
	vbox.add_child(resume_btn)

	# Save Game
	_save_btn = Button.new()
	_save_btn.text = "Save Game"
	_save_btn.custom_minimum_size = Vector2(200, 38)
	_save_btn.pressed.connect(_on_save)
	_save_btn.disabled = GameState.is_in_dungeon
	vbox.add_child(_save_btn)

	# Switch Character
	_switch_btn = Button.new()
	_switch_btn.text = "Switch Character"
	_switch_btn.custom_minimum_size = Vector2(200, 38)
	_switch_btn.pressed.connect(_on_switch_character)
	vbox.add_child(_switch_btn)

	# Load Game
	_load_btn = Button.new()
	_load_btn.text = "Load Game"
	_load_btn.custom_minimum_size = Vector2(200, 38)
	_load_btn.pressed.connect(_on_load)
	_load_btn.disabled = not SaveManager.has_any_save()
	vbox.add_child(_load_btn)

	# Main Menu
	var menu_btn := Button.new()
	menu_btn.text = "Main Menu"
	menu_btn.custom_minimum_size = Vector2(200, 38)
	menu_btn.pressed.connect(_on_main_menu)
	vbox.add_child(menu_btn)

	var hint := Label.new()
	hint.text = "Press ESC to resume"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)


func update_button_states() -> void:
	if _save_btn:
		_save_btn.disabled = GameState.is_in_dungeon
	if _load_btn:
		_load_btn.disabled = not SaveManager.has_any_save()
	if _switch_btn:
		_switch_btn.disabled = GameState.is_in_dungeon


func _on_resume() -> void:
	resumed.emit()


func _on_save() -> void:
	save_requested.emit()


func _on_switch_character() -> void:
	switch_character_requested.emit()


func _on_load() -> void:
	load_requested.emit()


func _on_main_menu() -> void:
	main_menu_requested.emit()
