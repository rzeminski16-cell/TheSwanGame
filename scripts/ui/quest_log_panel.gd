extends PanelContainer
## QuestLogPanel — Quest log popup with Active/Completed tabs, expandable mission boxes.
## Toggle with L key. Supports tracking, debug view, and auto-complete.

signal closed()

enum Tab { ACTIVE, COMPLETED, DEBUG }

const QUEST_TYPE_COLORS := {
	"main": Color(1.0, 0.85, 0.3),
	"side": Color(0.8, 0.8, 0.8),
	"character": Color(0.7, 0.4, 1.0),
}

const QUEST_TYPE_LABELS := {
	"main": "MAIN QUEST",
	"side": "SIDE QUEST",
	"character": "CHARACTER QUEST",
}

var _current_tab: int = Tab.ACTIVE
var _expanded_mission_id: String = ""
var _mission_list: VBoxContainer
var _tab_buttons: Array[Button] = []
var _scroll: ScrollContainer


func _ready() -> void:
	custom_minimum_size = Vector2(480, 520)
	set_anchors_preset(Control.PRESET_CENTER)
	_build_ui()
	_refresh()

	MissionManager.mission_started.connect(func(_id): _refresh())
	MissionManager.mission_completed.connect(func(_id): _refresh())
	MissionManager.objective_completed.connect(func(_id, _idx): _refresh())
	MissionManager.tracked_mission_changed.connect(func(_id): _refresh())


func _build_ui() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	bg.border_color = Color(0.4, 0.4, 0.6)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(8)
	bg.set_content_margin_all(12)
	add_theme_stylebox_override("panel", bg)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	add_child(root)

	# Header
	var header := HBoxContainer.new()
	root.add_child(header)

	var title := Label.new()
	title.text = "QUEST LOG"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(30, 30)
	close_btn.pressed.connect(func(): closed.emit())
	header.add_child(close_btn)

	root.add_child(HSeparator.new())

	# Tab bar
	var tab_bar := HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 4)
	root.add_child(tab_bar)

	var tab_names := ["Active", "Completed", "Debug"]
	for i in range(tab_names.size()):
		var btn := Button.new()
		btn.text = tab_names[i]
		btn.custom_minimum_size = Vector2(80, 28)
		btn.add_theme_font_size_override("font_size", 13)
		btn.toggle_mode = true
		btn.button_pressed = (i == _current_tab)
		var tab_index := i
		btn.pressed.connect(_on_tab_pressed.bind(tab_index))
		tab_bar.add_child(btn)
		_tab_buttons.append(btn)

	root.add_child(HSeparator.new())

	# Scrollable mission list
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.custom_minimum_size = Vector2(0, 350)
	root.add_child(_scroll)

	_mission_list = VBoxContainer.new()
	_mission_list.add_theme_constant_override("separation", 6)
	_mission_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_mission_list)

	# Footer
	var hint := Label.new()
	hint.text = "Press L to close"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hint)


func _on_tab_pressed(tab_index: int) -> void:
	_current_tab = tab_index
	_expanded_mission_id = ""
	for i in range(_tab_buttons.size()):
		_tab_buttons[i].button_pressed = (i == tab_index)
	_refresh()


func _refresh() -> void:
	if _mission_list == null:
		return

	# Clear list
	for child in _mission_list.get_children():
		child.queue_free()

	match _current_tab:
		Tab.ACTIVE:
			_populate_active()
		Tab.COMPLETED:
			_populate_completed()
		Tab.DEBUG:
			_populate_debug()


func _populate_active() -> void:
	var active_missions := MissionManager.get_all_active_missions()

	if active_missions.is_empty():
		_add_empty_label("No active quests.")
		return

	for mission_data in active_missions:
		var mid: String = mission_data.get("id", "")
		_add_mission_box(mission_data, mid == _expanded_mission_id, true)


func _populate_completed() -> void:
	var completed_missions := MissionManager.get_all_completed_missions()

	if completed_missions.is_empty():
		_add_empty_label("No completed quests yet.")
		return

	for mission_data in completed_missions:
		var mid: String = mission_data.get("id", "")
		_add_mission_box(mission_data, mid == _expanded_mission_id, false)


func _populate_debug() -> void:
	# Debug controls
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 4)
	_mission_list.add_child(controls)

	var complete_btn := Button.new()
	complete_btn.text = "Complete Tracked"
	complete_btn.custom_minimum_size = Vector2(0, 28)
	complete_btn.add_theme_font_size_override("font_size", 11)
	complete_btn.pressed.connect(_on_debug_complete_tracked)
	controls.add_child(complete_btn)

	var unlock_btn := Button.new()
	unlock_btn.text = "Start All Unlockable"
	unlock_btn.custom_minimum_size = Vector2(0, 28)
	unlock_btn.add_theme_font_size_override("font_size", 11)
	unlock_btn.pressed.connect(_on_debug_start_unlockable)
	controls.add_child(unlock_btn)

	var reset_btn := Button.new()
	reset_btn.text = "Reset All"
	reset_btn.custom_minimum_size = Vector2(0, 28)
	reset_btn.add_theme_font_size_override("font_size", 11)
	reset_btn.pressed.connect(_on_debug_reset_all)
	controls.add_child(reset_btn)

	_mission_list.add_child(HSeparator.new())

	# Header
	var header := Label.new()
	header.text = "ALL MISSIONS IN GAME"
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	_mission_list.add_child(header)

	# List every mission
	var all_missions := DataManager.get_all_missions()
	for mission_data in all_missions:
		_add_debug_mission_box(mission_data)


func _add_empty_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mission_list.add_child(label)


func _add_mission_box(mission_data: Dictionary, is_expanded: bool, is_active: bool) -> void:
	var mid: String = mission_data.get("id", "")
	var quest_type: String = mission_data.get("quest_type", "side")
	var is_tracked: bool = (mid == MissionManager.get_tracked_mission_id())

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()

	if is_tracked:
		style.bg_color = Color(0.12, 0.14, 0.22)
		style.border_color = Color(0.5, 0.7, 1.0)
	else:
		style.bg_color = Color(0.1, 0.1, 0.15)
		style.border_color = Color(0.25, 0.25, 0.35)

	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	# --- Collapsed header row ---
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)
	vbox.add_child(header_row)

	# Quest name
	var name_label := Label.new()
	name_label.text = mission_data.get("display_name", mid)
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", QUEST_TYPE_COLORS.get(quest_type, Color.WHITE))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(name_label)

	# Recommended level
	var level_label := Label.new()
	var rec_level: int = int(mission_data.get("recommended_level", 1))
	level_label.text = "Lv.%d" % rec_level
	level_label.add_theme_font_size_override("font_size", 11)
	level_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	header_row.add_child(level_label)

	# Quest type badge
	var type_label := Label.new()
	type_label.text = QUEST_TYPE_LABELS.get(quest_type, "QUEST")
	type_label.add_theme_font_size_override("font_size", 10)
	type_label.add_theme_color_override("font_color", QUEST_TYPE_COLORS.get(quest_type, Color.WHITE))
	header_row.add_child(type_label)

	# Tracking indicator
	if is_tracked:
		var track_indicator := Label.new()
		track_indicator.text = "[TRACKING]"
		track_indicator.add_theme_font_size_override("font_size", 10)
		track_indicator.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
		header_row.add_child(track_indicator)

	# --- Expanded content ---
	if is_expanded:
		vbox.add_child(HSeparator.new())

		# Description
		var desc := Label.new()
		desc.text = mission_data.get("description", "No description.")
		desc.add_theme_font_size_override("font_size", 12)
		desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(desc)

		# Objectives
		var objectives: Array = mission_data.get("objectives", [])
		var obj_status: Array = MissionManager.get_objective_status(mid)

		if objectives.size() > 0:
			var obj_header := Label.new()
			obj_header.text = "Objectives:"
			obj_header.add_theme_font_size_override("font_size", 12)
			obj_header.add_theme_color_override("font_color", Color(0.8, 0.8, 0.5))
			vbox.add_child(obj_header)

		for i in range(objectives.size()):
			var obj: Dictionary = objectives[i]
			var done: bool = obj_status[i] if i < obj_status.size() else false

			var obj_label := Label.new()
			var obj_desc := MissionManager._describe_objective(obj)
			if done:
				obj_label.text = "  [x] %s" % obj_desc
				obj_label.add_theme_color_override("font_color", Color(0.4, 0.7, 0.4))
			else:
				obj_label.text = "  [ ] %s" % obj_desc
				obj_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			obj_label.add_theme_font_size_override("font_size", 11)
			vbox.add_child(obj_label)

		# Track button (only for active quests)
		if is_active and not is_tracked:
			var track_btn := Button.new()
			track_btn.text = "Track This Quest"
			track_btn.custom_minimum_size = Vector2(0, 26)
			track_btn.add_theme_font_size_override("font_size", 11)
			track_btn.pressed.connect(MissionManager.track_mission.bind(mid))
			vbox.add_child(track_btn)

		# Rewards summary
		var rewards: Dictionary = mission_data.get("rewards", {})
		var reward_parts: Array = []
		var r_money: int = int(rewards.get("money", 0))
		var r_xp: int = int(rewards.get("xp", 0))
		var r_items: Array = rewards.get("items", [])
		if r_money > 0:
			reward_parts.append("$%d" % r_money)
		if r_xp > 0:
			reward_parts.append("%d XP" % r_xp)
		if r_items.size() > 0:
			reward_parts.append("%d item(s)" % r_items.size())

		if reward_parts.size() > 0:
			var reward_label := Label.new()
			reward_label.text = "Rewards: %s" % ", ".join(reward_parts)
			reward_label.add_theme_font_size_override("font_size", 11)
			reward_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
			vbox.add_child(reward_label)

	# Click to toggle expand/collapse
	panel.gui_input.connect(_on_mission_box_input.bind(mid))
	_mission_list.add_child(panel)


func _add_debug_mission_box(mission_data: Dictionary) -> void:
	var mid: String = mission_data.get("id", "")
	var quest_type: String = mission_data.get("quest_type", "side")
	var state: int = MissionManager.get_mission_state(mid)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(6)

	match state:
		MissionManager.MissionState.COMPLETED:
			style.border_color = Color(0.3, 0.6, 0.3)
		MissionManager.MissionState.ACTIVE:
			style.border_color = Color(0.5, 0.5, 0.8)
		MissionManager.MissionState.FAILED:
			style.border_color = Color(0.6, 0.3, 0.3)
		_:
			style.border_color = Color(0.2, 0.2, 0.25)

	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	# Name + state
	var header := HBoxContainer.new()
	vbox.add_child(header)

	var name_label := Label.new()
	name_label.text = mission_data.get("display_name", mid)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", QUEST_TYPE_COLORS.get(quest_type, Color.WHITE))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	var state_label := Label.new()
	match state:
		MissionManager.MissionState.COMPLETED:
			state_label.text = "DONE"
			state_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
		MissionManager.MissionState.ACTIVE:
			state_label.text = "ACTIVE"
			state_label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
		MissionManager.MissionState.FAILED:
			state_label.text = "FAILED"
			state_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		_:
			state_label.text = "LOCKED"
			state_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	state_label.add_theme_font_size_override("font_size", 10)
	header.add_child(state_label)

	# Unlock conditions
	var unlock_text: String = mission_data.get("unlock_conditions", "Unknown")
	var unlock_label := Label.new()
	unlock_label.text = "Unlock: %s" % unlock_text
	unlock_label.add_theme_font_size_override("font_size", 10)
	unlock_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	unlock_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(unlock_label)

	# Debug start button for locked missions
	if state == MissionManager.MissionState.NOT_STARTED:
		var start_btn := Button.new()
		start_btn.text = "Force Start"
		start_btn.custom_minimum_size = Vector2(0, 22)
		start_btn.add_theme_font_size_override("font_size", 10)
		start_btn.pressed.connect(func():
			MissionManager.start_mission(mid)
			_refresh()
		)
		vbox.add_child(start_btn)

	_mission_list.add_child(panel)


func _on_mission_box_input(event: InputEvent, mission_id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _expanded_mission_id == mission_id:
			_expanded_mission_id = ""
		else:
			_expanded_mission_id = mission_id
		_refresh()


# --- Debug Actions ---

func _on_debug_complete_tracked() -> void:
	var tid := MissionManager.get_tracked_mission_id()
	if tid != "":
		MissionManager.debug_complete_mission(tid)
	_refresh()


func _on_debug_start_unlockable() -> void:
	var unlockable := MissionManager.get_unlockable_missions()
	for mission_data in unlockable:
		MissionManager.start_mission(mission_data.get("id", ""))
	_refresh()


func _on_debug_reset_all() -> void:
	MissionManager._mission_states.clear()
	MissionManager._objective_status.clear()
	MissionManager._kill_counts.clear()
	GameState.active_mission_ids.clear()
	GameState.tracked_mission_id = ""
	GameState.current_mission_id = ""
	print("QuestLogPanel: DEBUG — All missions reset")
	_refresh()
