extends PanelContainer
## MainMenu — Title screen with New Game, Continue, Host Game, Join Game, Quit.
## Loaded by UIManager on game start.

signal new_game_pressed()
signal continue_pressed()
signal host_game_pressed()
signal join_game_pressed(address: String)
signal quit_pressed()

var _continue_btn: Button
var _host_btn: Button
var _join_btn: Button
var _ip_input: LineEdit
var _status_label: Label
var _player_count_spin: SpinBox


func _ready() -> void:
	custom_minimum_size = Vector2(400, 520)
	size = Vector2(400, 520)
	var vp_size := get_viewport_rect().size
	position = Vector2((vp_size.x - 400) / 2.0, (vp_size.y - 520) / 2.0)
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

	# --- Single Player ---
	var sp_label := Label.new()
	sp_label.text = "Single Player"
	sp_label.add_theme_font_size_override("font_size", 13)
	sp_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
	sp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sp_label)

	# New Game button
	var new_game_btn := Button.new()
	new_game_btn.text = "New Game"
	new_game_btn.custom_minimum_size = Vector2(250, 38)
	new_game_btn.pressed.connect(func(): new_game_pressed.emit())
	vbox.add_child(new_game_btn)

	# Continue button
	_continue_btn = Button.new()
	_continue_btn.text = "Continue"
	_continue_btn.custom_minimum_size = Vector2(250, 38)
	_continue_btn.pressed.connect(func(): continue_pressed.emit())
	vbox.add_child(_continue_btn)

	vbox.add_child(HSeparator.new())

	# --- Multiplayer ---
	var mp_label := Label.new()
	mp_label.text = "LAN Multiplayer"
	mp_label.add_theme_font_size_override("font_size", 13)
	mp_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
	mp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(mp_label)

	# Player count row
	var count_row := HBoxContainer.new()
	count_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var count_label := Label.new()
	count_label.text = "Players: "
	count_label.add_theme_font_size_override("font_size", 12)
	count_row.add_child(count_label)
	_player_count_spin = SpinBox.new()
	_player_count_spin.min_value = 1
	_player_count_spin.max_value = 4
	_player_count_spin.value = 2
	_player_count_spin.step = 1
	_player_count_spin.custom_minimum_size = Vector2(70, 30)
	count_row.add_child(_player_count_spin)
	vbox.add_child(count_row)

	# Host Game button
	_host_btn = Button.new()
	_host_btn.text = "Host Game"
	_host_btn.custom_minimum_size = Vector2(250, 38)
	_host_btn.pressed.connect(_on_host_pressed)
	vbox.add_child(_host_btn)

	# Join row: IP input + Join button
	var join_row := HBoxContainer.new()
	join_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_ip_input = LineEdit.new()
	_ip_input.placeholder_text = "IP Address"
	_ip_input.text = "127.0.0.1"
	_ip_input.custom_minimum_size = Vector2(150, 36)
	_ip_input.add_theme_font_size_override("font_size", 12)
	join_row.add_child(_ip_input)
	_join_btn = Button.new()
	_join_btn.text = "Join"
	_join_btn.custom_minimum_size = Vector2(90, 36)
	_join_btn.pressed.connect(_on_join_pressed)
	join_row.add_child(_join_btn)
	vbox.add_child(join_row)

	# Status label
	_status_label = Label.new()
	_status_label.text = ""
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.4))
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_status_label)

	vbox.add_child(HSeparator.new())

	# Quit button
	var quit_btn := Button.new()
	quit_btn.text = "Quit"
	quit_btn.custom_minimum_size = Vector2(250, 38)
	quit_btn.pressed.connect(func(): quit_pressed.emit())
	vbox.add_child(quit_btn)

	_refresh_buttons()


func _on_host_pressed() -> void:
	var player_count := int(_player_count_spin.value)
	GameState.player_count = player_count
	host_game_pressed.emit()


func _on_join_pressed() -> void:
	var address := _ip_input.text.strip_edges()
	if address == "":
		address = "127.0.0.1"
	join_game_pressed.emit(address)


func set_status(text: String) -> void:
	if _status_label:
		_status_label.text = text


func refresh() -> void:
	## Called by UIManager each time the menu is shown to update button states.
	_refresh_buttons()


func _refresh_buttons() -> void:
	if _continue_btn:
		_continue_btn.disabled = not SaveManager.has_save()
