extends PanelContainer
## NewGamePanel — Multi-step new game creation flow.
## Step 1: Select empty save slot
## Step 2: Name the world
## Step 3: Select a character
## Emits start_game when complete.

signal start_game(slot_index: int, world_name: String, character_id: String)
signal back_pressed()

var _current_step: int = 0
var _selected_slot: int = -1
var _world_name: String = ""
var _selected_character: String = ""

var _step_container: VBoxContainer = null
var _title_label: Label = null

# Step 1: Slot selection
var _slot_buttons: Array = []

# Step 2: Name input
var _name_input: LineEdit = null

# Step 3: Character cards
var _char_buttons: Dictionary = {}
var _start_btn: Button = null


func _ready() -> void:
	custom_minimum_size = Vector2(600, 560)
	size = Vector2(600, 560)
	var vp_size := get_viewport_rect().size
	position = Vector2((vp_size.x - 600) / 2.0, (vp_size.y - 560) / 2.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_shell()
	_show_step(0)


func _build_shell() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.04, 0.04, 0.07, 0.98)
	bg.border_color = Color(0.4, 0.4, 0.55)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(12)
	bg.set_content_margin_all(20)
	add_theme_stylebox_override("panel", bg)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	add_child(outer)

	# Title
	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(_title_label)

	outer.add_child(HSeparator.new())

	# Step container (swapped out per step)
	_step_container = VBoxContainer.new()
	_step_container.add_theme_constant_override("separation", 10)
	_step_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(_step_container)


func _clear_step() -> void:
	for child in _step_container.get_children():
		child.queue_free()
	_slot_buttons.clear()
	_char_buttons.clear()
	_name_input = null
	_start_btn = null


func _show_step(step: int) -> void:
	_current_step = step
	_clear_step()

	match step:
		0:
			_build_step_slot()
		1:
			_build_step_name()
		2:
			_build_step_character()


func _build_step_slot() -> void:
	_title_label.text = "New Game — Select Save Slot"

	var all_info := SaveManager.get_all_slot_info()
	for i in range(SaveManager.SAVE_SLOT_COUNT):
		var slot_index := i + 1
		var info: Dictionary = all_info[i]
		var is_occupied := not info.is_empty()

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(400, 44)
		if is_occupied:
			var wname: String = info.get("world_name", "World")
			btn.text = "  Slot %d: %s (occupied)" % [slot_index, wname]
			btn.disabled = true
		else:
			btn.text = "  Slot %d: — Empty —" % slot_index
			btn.disabled = false
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_slot_selected.bind(slot_index))
		_step_container.add_child(btn)
		_slot_buttons.append(btn)

	_step_container.add_child(HSeparator.new())

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(120, 34)
	back_btn.pressed.connect(func(): back_pressed.emit())
	_step_container.add_child(back_btn)


func _on_slot_selected(slot_index: int) -> void:
	_selected_slot = slot_index
	_show_step(1)


func _build_step_name() -> void:
	_title_label.text = "New Game — Name Your World"

	var info_label := Label.new()
	info_label.text = "Enter a name for your world (Slot %d):" % _selected_slot
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	_step_container.add_child(info_label)

	_name_input = LineEdit.new()
	_name_input.placeholder_text = "World name..."
	_name_input.text = "World %d" % _selected_slot
	_name_input.max_length = 24
	_name_input.custom_minimum_size = Vector2(300, 38)
	_name_input.add_theme_font_size_override("font_size", 16)
	_step_container.add_child(_name_input)

	# Focus the input
	_name_input.call_deferred("grab_focus")

	_step_container.add_child(HSeparator.new())

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 20)
	_step_container.add_child(btn_row)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(120, 34)
	back_btn.pressed.connect(func(): _show_step(0))
	btn_row.add_child(back_btn)

	var next_btn := Button.new()
	next_btn.text = "Next"
	next_btn.custom_minimum_size = Vector2(120, 34)
	next_btn.pressed.connect(_on_name_confirmed)
	btn_row.add_child(next_btn)

	# Also allow pressing Enter
	_name_input.text_submitted.connect(func(_t): _on_name_confirmed())


func _on_name_confirmed() -> void:
	if _name_input:
		_world_name = _name_input.text.strip_edges()
		if _world_name == "":
			_world_name = "World %d" % _selected_slot
	_show_step(2)


func _build_step_character() -> void:
	_title_label.text = "New Game — Select Character"

	var subtitle := Label.new()
	subtitle.text = "World: \"%s\" (Slot %d)" % [_world_name, _selected_slot]
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_step_container.add_child(subtitle)

	# Character grid (2x2)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	_step_container.add_child(grid)

	var characters := DataManager.get_all_characters()
	for char_data in characters:
		var card := _create_char_card(char_data)
		grid.add_child(card)

	_step_container.add_child(HSeparator.new())

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 20)
	_step_container.add_child(btn_row)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(120, 36)
	back_btn.pressed.connect(func(): _show_step(1))
	btn_row.add_child(back_btn)

	_start_btn = Button.new()
	_start_btn.text = "Start Game"
	_start_btn.custom_minimum_size = Vector2(160, 36)
	_start_btn.disabled = true
	_start_btn.pressed.connect(_on_start)
	btn_row.add_child(_start_btn)


func _create_char_card(char_data: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(250, 120)

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

	# Name + color
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	vbox.add_child(name_row)

	var color_arr: Array = char_data.get("color", [0.5, 0.5, 0.5, 1.0])
	var char_color := Color(color_arr[0], color_arr[1], color_arr[2], color_arr[3])

	var color_rect := ColorRect.new()
	color_rect.custom_minimum_size = Vector2(18, 18)
	color_rect.color = char_color
	name_row.add_child(color_rect)

	var name_label := Label.new()
	name_label.text = char_data.get("display_name", "???")
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", char_color)
	name_row.add_child(name_label)

	# Description
	var desc := Label.new()
	desc.text = char_data.get("description", "")
	desc.add_theme_font_size_override("font_size", 10)
	desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	# Stat mods
	var mods: Dictionary = char_data.get("base_stat_modifiers", {})
	var mod_text := ""
	for key in mods:
		var val = mods[key]
		var stat_name: String = key.replace("_flat", "").replace("_percent", "").replace("_", " ").capitalize()
		if key.ends_with("_percent"):
			mod_text += "%+d%% %s  " % [int(val * 100), stat_name]
		else:
			mod_text += "%+d %s  " % [int(val), stat_name]
	var stats_label := Label.new()
	stats_label.text = mod_text.strip_edges()
	stats_label.add_theme_font_size_override("font_size", 10)
	stats_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
	vbox.add_child(stats_label)

	# Click to select
	var char_id: String = char_data.get("id", "")
	var select_btn := Button.new()
	select_btn.text = "Select"
	select_btn.custom_minimum_size = Vector2(70, 26)
	select_btn.pressed.connect(_on_char_clicked.bind(char_id, card))
	vbox.add_child(select_btn)

	_char_buttons[char_id] = card
	return card


func _on_char_clicked(char_id: String, _card: PanelContainer) -> void:
	_selected_character = char_id
	_highlight_selected()
	if _start_btn:
		_start_btn.disabled = false


func _highlight_selected() -> void:
	for cid in _char_buttons:
		var card: PanelContainer = _char_buttons[cid]
		var bg := card.get_theme_stylebox("panel") as StyleBoxFlat
		if bg:
			if cid == _selected_character:
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


func _on_start() -> void:
	if _selected_slot > 0 and _selected_character != "":
		if _world_name == "":
			_world_name = "World %d" % _selected_slot
		start_game.emit(_selected_slot, _world_name, _selected_character)
