extends PanelContainer
## MainMenu — Title screen with New Game, Load Game, Quit.
## Multiplayer hidden for now.

signal new_game_pressed()
signal load_game_pressed()
signal quit_pressed()

var _load_btn: Button


func _ready() -> void:
	custom_minimum_size = Vector2(400, 360)
	size = Vector2(400, 360)
	var vp_size := get_viewport_rect().size
	position = Vector2((vp_size.x - 400) / 2.0, (vp_size.y - 360) / 2.0)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_build_ui()


func _build_ui() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.04, 0.04, 0.07, 0.98)
	bg.border_color = Color(0.4, 0.4, 0.55)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(12)
	bg.set_content_margin_all(30)
	add_theme_stylebox_override("panel", bg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "THE SWAN GAME"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "A Bay Campus Adventure"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	vbox.add_child(HSeparator.new())

	# New Game button
	var new_game_btn := Button.new()
	new_game_btn.text = "New Game"
	new_game_btn.custom_minimum_size = Vector2(250, 38)
	new_game_btn.pressed.connect(func(): new_game_pressed.emit())
	vbox.add_child(new_game_btn)

	# Load Game button
	_load_btn = Button.new()
	_load_btn.text = "Load Game"
	_load_btn.custom_minimum_size = Vector2(250, 38)
	_load_btn.pressed.connect(func(): load_game_pressed.emit())
	vbox.add_child(_load_btn)

	vbox.add_child(HSeparator.new())

	# Quit button
	var quit_btn := Button.new()
	quit_btn.text = "Quit"
	quit_btn.custom_minimum_size = Vector2(250, 38)
	quit_btn.pressed.connect(func(): quit_pressed.emit())
	vbox.add_child(quit_btn)

	_refresh_buttons()


func refresh() -> void:
	_refresh_buttons()


func _refresh_buttons() -> void:
	if _load_btn:
		_load_btn.disabled = not SaveManager.has_any_save()
