extends PanelContainer
## CharacterSelectPanel — Shows 4 character cards to pick from.
## Used when loading a save (pick which character), starting new game, or switching mid-game.

signal character_selected(character_id: String)
signal back_pressed()

var _selected_id: String = ""
var _char_buttons: Dictionary = {}  # character_id → Button
var _confirm_btn: Button = null
var _slot_data: Dictionary = {}  # Optional: slot info for showing character levels


func _ready() -> void:
	custom_minimum_size = Vector2(600, 480)
	size = Vector2(600, 480)
	var vp_size := get_viewport_rect().size
	position = Vector2((vp_size.x - 600) / 2.0, (vp_size.y - 480) / 2.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()


func setup(slot_info: Dictionary = {}) -> void:
	## Pass slot_info from SaveManager.get_slot_info() to show character levels.
	_slot_data = slot_info
	_selected_id = ""
	_refresh()


func _build_ui() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.04, 0.04, 0.07, 0.98)
	bg.border_color = Color(0.4, 0.4, 0.55)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(12)
	bg.set_content_margin_all(20)
	add_theme_stylebox_override("panel", bg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Select Character"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# Character grid (2x2)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	vbox.add_child(grid)

	var characters := DataManager.get_all_characters()
	for char_data in characters:
		var card := _create_character_card(char_data)
		grid.add_child(card)

	vbox.add_child(HSeparator.new())

	# Bottom buttons
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(120, 36)
	back_btn.pressed.connect(func(): back_pressed.emit())
	btn_row.add_child(back_btn)

	_confirm_btn = Button.new()
	_confirm_btn.text = "Confirm"
	_confirm_btn.custom_minimum_size = Vector2(120, 36)
	_confirm_btn.disabled = true
	_confirm_btn.pressed.connect(_on_confirm)
	btn_row.add_child(_confirm_btn)


func _create_character_card(char_data: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(250, 130)

	var card_bg := StyleBoxFlat.new()
	card_bg.bg_color = Color(0.08, 0.08, 0.12, 0.9)
	card_bg.border_color = Color(0.3, 0.3, 0.4)
	card_bg.set_border_width_all(1)
	card_bg.set_corner_radius_all(8)
	card_bg.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", card_bg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	# Name row with color indicator
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	vbox.add_child(name_row)

	var color_arr: Array = char_data.get("color", [0.5, 0.5, 0.5, 1.0])
	var char_color := Color(color_arr[0], color_arr[1], color_arr[2], color_arr[3])

	var color_rect := ColorRect.new()
	color_rect.custom_minimum_size = Vector2(20, 20)
	color_rect.color = char_color
	name_row.add_child(color_rect)

	var name_label := Label.new()
	name_label.text = char_data.get("display_name", "???")
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", char_color)
	name_row.add_child(name_label)

	# Description
	var desc := Label.new()
	desc.text = char_data.get("description", "")
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	# Stat modifiers summary
	var mods: Dictionary = char_data.get("base_stat_modifiers", {})
	var mod_text := ""
	for key in mods:
		var val = mods[key]
		var stat_name: String = key.replace("_flat", "").replace("_percent", "").replace("_", " ").capitalize()
		if key.ends_with("_percent"):
			if val > 0:
				mod_text += "+%d%% %s  " % [int(val * 100), stat_name]
			else:
				mod_text += "%d%% %s  " % [int(val * 100), stat_name]
		else:
			if val > 0:
				mod_text += "+%d %s  " % [int(val), stat_name]
			else:
				mod_text += "%d %s  " % [int(val), stat_name]

	var stats_label := Label.new()
	stats_label.text = mod_text.strip_edges()
	stats_label.add_theme_font_size_override("font_size", 10)
	stats_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
	vbox.add_child(stats_label)

	# Select button
	var char_id: String = char_data.get("id", "")
	var select_btn := Button.new()
	select_btn.text = "Select"
	select_btn.custom_minimum_size = Vector2(80, 28)
	select_btn.pressed.connect(_on_char_clicked.bind(char_id, card))
	vbox.add_child(select_btn)

	_char_buttons[char_id] = card
	return card


func _on_char_clicked(char_id: String, card: PanelContainer) -> void:
	_selected_id = char_id
	_highlight_selected()
	if _confirm_btn:
		_confirm_btn.disabled = false


func _highlight_selected() -> void:
	for cid in _char_buttons:
		var card: PanelContainer = _char_buttons[cid]
		var bg := card.get_theme_stylebox("panel") as StyleBoxFlat
		if bg:
			if cid == _selected_id:
				bg.border_color = Color(1.0, 0.85, 0.3)
				bg.border_width_left = 3
				bg.border_width_right = 3
				bg.border_width_top = 3
				bg.border_width_bottom = 3
			else:
				bg.border_color = Color(0.3, 0.3, 0.4)
				bg.border_width_left = 1
				bg.border_width_right = 1
				bg.border_width_top = 1
				bg.border_width_bottom = 1


func _on_confirm() -> void:
	if _selected_id != "":
		character_selected.emit(_selected_id)


func _refresh() -> void:
	_highlight_selected()
	if _confirm_btn:
		_confirm_btn.disabled = (_selected_id == "")
