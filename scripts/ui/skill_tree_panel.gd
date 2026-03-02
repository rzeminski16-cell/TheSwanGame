extends PanelContainer
## SkillTreePanel — Displays the 15-node skill tree in 3 categories.
## Toggle with K key. Skill nodes show locked/unlocked state.
## Click an available node to unlock it (costs 1 SP).

signal closed()

var _player_id: int = 1
var _category_containers: Dictionary = {}  # category → VBoxContainer
var _skill_buttons: Dictionary = {}  # skill_id → Button
var _sp_label: Label
var _title_label: Label

const CATEGORY_COLORS := {
	"combat": Color(0.9, 0.3, 0.3),
	"economy": Color(1.0, 0.85, 0.2),
	"personality": Color(0.4, 0.7, 1.0),
}

const CATEGORY_NAMES := {
	"combat": "Combat",
	"economy": "Economy",
	"personality": "Personality",
}


func _ready() -> void:
	custom_minimum_size = Vector2(700, 450)
	set_anchors_preset(Control.PRESET_CENTER)
	_build_ui()
	_refresh()

	SkillManager.skill_unlocked.connect(_on_skill_unlocked)
	PlayerManager.player_leveled_up.connect(_on_level_up)


func _build_ui() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	bg.border_color = Color(0.4, 0.4, 0.6)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(8)
	bg.set_content_margin_all(12)
	add_theme_stylebox_override("panel", bg)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	add_child(root_vbox)

	# Header row
	var header := HBoxContainer.new()
	root_vbox.add_child(header)

	_title_label = Label.new()
	_title_label.text = "SKILL TREE"
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)

	_sp_label = Label.new()
	_sp_label.add_theme_font_size_override("font_size", 16)
	_sp_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
	header.add_child(_sp_label)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(30, 30)
	close_btn.pressed.connect(_on_close_pressed)
	header.add_child(close_btn)

	# Separator
	var sep := HSeparator.new()
	root_vbox.add_child(sep)

	# Category columns
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(columns)

	for category in ["combat", "economy", "personality"]:
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 4)
		columns.add_child(col)

		var cat_label := Label.new()
		cat_label.text = CATEGORY_NAMES[category]
		cat_label.add_theme_font_size_override("font_size", 16)
		cat_label.add_theme_color_override("font_color", CATEGORY_COLORS[category])
		cat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(cat_label)

		var cat_sep := HSeparator.new()
		col.add_child(cat_sep)

		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		col.add_child(scroll)

		var skill_list := VBoxContainer.new()
		skill_list.add_theme_constant_override("separation", 4)
		skill_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(skill_list)

		_category_containers[category] = skill_list

	# Build skill nodes
	for category in ["combat", "economy", "personality"]:
		var skills: Array = DataManager.get_skills_by_category(category)
		var container: VBoxContainer = _category_containers[category]

		for skill in skills:
			var sid: String = skill.get("id", "")
			var btn := _create_skill_button(skill)
			container.add_child(btn)
			_skill_buttons[sid] = btn

	# Footer hint
	var hint := Label.new()
	hint.text = "Press K to close  |  Click an available skill to unlock"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(hint)


func _create_skill_button(skill: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(180, 50)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	var sid: String = skill.get("id", "")
	btn.pressed.connect(_on_skill_pressed.bind(sid))

	return btn


func _refresh() -> void:
	_sp_label.text = "SP: %d" % PlayerManager.get_skill_points(_player_id)

	for skill in DataManager.get_all_skills():
		var sid: String = skill.get("id", "")
		if not _skill_buttons.has(sid):
			continue

		var btn: Button = _skill_buttons[sid]
		var unlocked := SkillManager.is_skill_unlocked(_player_id, sid)
		var available := SkillManager.can_unlock_skill(_player_id, sid)

		# Build display text
		var display_name: String = skill.get("display_name", sid)
		var description: String = skill.get("description", "")
		var reqs: Array = skill.get("requirements", [])

		var text := "%s\n%s" % [display_name, description]
		btn.text = text

		if unlocked:
			btn.disabled = true
			btn.tooltip_text = "Unlocked"
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.15, 0.4, 0.15)
			style.set_border_width_all(1)
			style.border_color = Color(0.3, 0.8, 0.3)
			style.set_corner_radius_all(4)
			btn.add_theme_stylebox_override("disabled", style)
			btn.add_theme_color_override("font_disabled_color", Color(0.7, 1.0, 0.7))
		elif available:
			btn.disabled = false
			btn.tooltip_text = "Click to unlock (1 SP)"
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.2, 0.2, 0.35)
			style.set_border_width_all(1)
			style.border_color = Color(0.5, 0.5, 1.0)
			style.set_corner_radius_all(4)
			btn.add_theme_stylebox_override("normal", style)
			var hover := StyleBoxFlat.new()
			hover.bg_color = Color(0.25, 0.25, 0.45)
			hover.set_border_width_all(1)
			hover.border_color = Color(0.6, 0.6, 1.0)
			hover.set_corner_radius_all(4)
			btn.add_theme_stylebox_override("hover", hover)
		else:
			btn.disabled = true
			var req_names: Array = []
			for rid in reqs:
				if not SkillManager.is_skill_unlocked(_player_id, rid):
					var rskill: Dictionary = DataManager.get_skill(rid)
					req_names.append(rskill.get("display_name", rid))
			if req_names.size() > 0:
				btn.tooltip_text = "Requires: %s" % ", ".join(req_names)
			elif PlayerManager.get_skill_points(_player_id) <= 0:
				btn.tooltip_text = "No skill points available"
			else:
				btn.tooltip_text = "Locked"
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.12, 0.12, 0.12)
			style.set_border_width_all(1)
			style.border_color = Color(0.25, 0.25, 0.25)
			style.set_corner_radius_all(4)
			btn.add_theme_stylebox_override("disabled", style)
			btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))


func _on_skill_pressed(skill_id: String) -> void:
	if SkillManager.unlock_skill(_player_id, skill_id):
		_refresh()


func _on_skill_unlocked(_pid: int, _sid: String) -> void:
	_refresh()


func _on_level_up(_pid: int, _lvl: int) -> void:
	_refresh()


func _on_close_pressed() -> void:
	closed.emit()
