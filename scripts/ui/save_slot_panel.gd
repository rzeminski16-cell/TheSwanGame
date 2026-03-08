extends PanelContainer
## SaveSlotPanel — Shows 5 save slots for loading or selecting empty slots for new games.
## Reused by main menu (load/new game) and pause menu (load).

enum Mode { LOAD, NEW_GAME }

signal slot_selected(slot_index: int)
signal slot_delete_requested(slot_index: int)
signal back_pressed()

var _mode: int = Mode.LOAD
var _slot_buttons: Array = []
var _delete_buttons: Array = []
var _confirm_delete_slot: int = -1
var _confirm_panel: PanelContainer = null
var _vbox: VBoxContainer = null


func _ready() -> void:
	custom_minimum_size = Vector2(500, 520)
	size = Vector2(500, 520)
	var vp_size := get_viewport_rect().size
	position = Vector2((vp_size.x - 500) / 2.0, (vp_size.y - 520) / 2.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()


func setup(mode: int) -> void:
	_mode = mode
	_refresh_slots()


func _build_ui() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.04, 0.04, 0.07, 0.98)
	bg.border_color = Color(0.4, 0.4, 0.55)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(12)
	bg.set_content_margin_all(20)
	add_theme_stylebox_override("panel", bg)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 10)
	add_child(_vbox)

	# Title
	var title := Label.new()
	title.text = "Save Slots"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox.add_child(title)

	_vbox.add_child(HSeparator.new())

	# 5 slot rows
	for i in range(1, SaveManager.SAVE_SLOT_COUNT + 1):
		var row := _create_slot_row(i)
		_vbox.add_child(row)

	_vbox.add_child(HSeparator.new())

	# Back button
	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(120, 34)
	back_btn.pressed.connect(func(): back_pressed.emit())
	_vbox.add_child(back_btn)


func _create_slot_row(slot_index: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	# Slot button (main clickable area)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(360, 50)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.pressed.connect(_on_slot_pressed.bind(slot_index))
	row.add_child(btn)
	_slot_buttons.append(btn)

	# Delete button (only shown in LOAD mode for occupied slots)
	var del_btn := Button.new()
	del_btn.text = "X"
	del_btn.custom_minimum_size = Vector2(40, 50)
	del_btn.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	del_btn.pressed.connect(_on_delete_pressed.bind(slot_index))
	row.add_child(del_btn)
	_delete_buttons.append(del_btn)

	return row


func _refresh_slots() -> void:
	var all_info := SaveManager.get_all_slot_info()

	for i in range(SaveManager.SAVE_SLOT_COUNT):
		var slot_index := i + 1
		var info: Dictionary = all_info[i]
		var btn: Button = _slot_buttons[i]
		var del_btn: Button = _delete_buttons[i]
		var is_occupied := not info.is_empty()

		if is_occupied:
			var world_name: String = info.get("world_name", "World")
			var day: int = info.get("day", 1)
			var chars: Array = info.get("characters", [])
			var char_names := []
			for c in chars:
				char_names.append(c.get("display_name", "?"))
			btn.text = "  Slot %d: %s  —  Day %d" % [slot_index, world_name, day]
		else:
			btn.text = "  Slot %d: — Empty —" % slot_index

		# Enable/disable based on mode
		if _mode == Mode.LOAD:
			btn.disabled = not is_occupied
			del_btn.visible = is_occupied
		else:  # NEW_GAME
			btn.disabled = is_occupied
			del_btn.visible = false


func _on_slot_pressed(slot_index: int) -> void:
	slot_selected.emit(slot_index)


func _on_delete_pressed(slot_index: int) -> void:
	_confirm_delete_slot = slot_index
	_show_confirm_dialog(slot_index)


func _show_confirm_dialog(slot_index: int) -> void:
	if _confirm_panel:
		_confirm_panel.queue_free()

	_confirm_panel = PanelContainer.new()
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.05, 0.05, 0.98)
	bg.border_color = Color(0.8, 0.3, 0.3)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(8)
	bg.set_content_margin_all(16)
	_confirm_panel.add_theme_stylebox_override("panel", bg)
	_confirm_panel.custom_minimum_size = Vector2(300, 120)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_confirm_panel.add_child(vbox)

	var label := Label.new()
	label.text = "Delete save slot %d?" % slot_index
	label.add_theme_font_size_override("font_size", 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	var warn := Label.new()
	warn.text = "This cannot be undone!"
	warn.add_theme_font_size_override("font_size", 12)
	warn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(warn)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_row)

	var yes_btn := Button.new()
	yes_btn.text = "Delete"
	yes_btn.custom_minimum_size = Vector2(100, 34)
	yes_btn.pressed.connect(_on_confirm_delete)
	btn_row.add_child(yes_btn)

	var no_btn := Button.new()
	no_btn.text = "Cancel"
	no_btn.custom_minimum_size = Vector2(100, 34)
	no_btn.pressed.connect(_on_cancel_delete)
	btn_row.add_child(no_btn)

	add_child(_confirm_panel)
	_confirm_panel.position = Vector2(100, 200)


func _on_confirm_delete() -> void:
	if _confirm_delete_slot > 0:
		slot_delete_requested.emit(_confirm_delete_slot)
		SaveManager.delete_save(_confirm_delete_slot)
		_refresh_slots()
	_dismiss_confirm()


func _on_cancel_delete() -> void:
	_dismiss_confirm()


func _dismiss_confirm() -> void:
	_confirm_delete_slot = -1
	if _confirm_panel:
		_confirm_panel.queue_free()
		_confirm_panel = null
