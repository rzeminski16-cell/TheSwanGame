extends Control
## HUD — In-game heads-up display.
## Shows health bar, stamina bar, XP bar, level, money, item count, skill points.
## Updates every frame from manager state.

var _player_id: int = 1

# Node references (built in _ready)
var _health_bar: ProgressBar
var _health_label: Label
var _stamina_bar: ProgressBar
var _stamina_label: Label
var _xp_bar: ProgressBar
var _xp_label: Label
var _level_label: Label
var _money_label: Label
var _item_count_label: Label
var _sp_label: Label
var _rent_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func _build_ui() -> void:
	# Top-left: Health + Stamina bars
	var top_left := VBoxContainer.new()
	top_left.position = Vector2(10, 10)
	top_left.custom_minimum_size = Vector2(220, 0)
	top_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_left)

	# Health bar
	var hp_row := HBoxContainer.new()
	hp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_left.add_child(hp_row)

	var hp_icon := Label.new()
	hp_icon.text = "HP "
	hp_icon.add_theme_font_size_override("font_size", 12)
	hp_icon.add_theme_color_override("font_color", Color.RED)
	hp_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_row.add_child(hp_icon)

	_health_bar = ProgressBar.new()
	_health_bar.custom_minimum_size = Vector2(150, 16)
	_health_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_health_bar.show_percentage = false
	_health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hp_style := StyleBoxFlat.new()
	hp_style.bg_color = Color(0.8, 0.1, 0.1)
	_health_bar.add_theme_stylebox_override("fill", hp_style)
	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.2, 0.05, 0.05)
	_health_bar.add_theme_stylebox_override("background", hp_bg)
	hp_row.add_child(_health_bar)

	_health_label = Label.new()
	_health_label.add_theme_font_size_override("font_size", 11)
	_health_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_row.add_child(_health_label)

	# Stamina bar
	var st_row := HBoxContainer.new()
	st_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_left.add_child(st_row)

	var st_icon := Label.new()
	st_icon.text = "ST "
	st_icon.add_theme_font_size_override("font_size", 12)
	st_icon.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	st_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	st_row.add_child(st_icon)

	_stamina_bar = ProgressBar.new()
	_stamina_bar.custom_minimum_size = Vector2(150, 16)
	_stamina_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stamina_bar.show_percentage = false
	_stamina_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st_style := StyleBoxFlat.new()
	st_style.bg_color = Color(0.2, 0.7, 0.2)
	_stamina_bar.add_theme_stylebox_override("fill", st_style)
	var st_bg := StyleBoxFlat.new()
	st_bg.bg_color = Color(0.05, 0.2, 0.05)
	_stamina_bar.add_theme_stylebox_override("background", st_bg)
	st_row.add_child(_stamina_bar)

	_stamina_label = Label.new()
	_stamina_label.add_theme_font_size_override("font_size", 11)
	_stamina_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	st_row.add_child(_stamina_label)

	# XP bar
	var xp_row := HBoxContainer.new()
	xp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_left.add_child(xp_row)

	var xp_icon := Label.new()
	xp_icon.text = "XP "
	xp_icon.add_theme_font_size_override("font_size", 12)
	xp_icon.add_theme_color_override("font_color", Color(0.3, 0.5, 1.0))
	xp_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xp_row.add_child(xp_icon)

	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(150, 14)
	_xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_xp_bar.show_percentage = false
	_xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var xp_style := StyleBoxFlat.new()
	xp_style.bg_color = Color(0.3, 0.5, 1.0)
	_xp_bar.add_theme_stylebox_override("fill", xp_style)
	var xp_bg := StyleBoxFlat.new()
	xp_bg.bg_color = Color(0.1, 0.1, 0.3)
	_xp_bar.add_theme_stylebox_override("background", xp_bg)
	xp_row.add_child(_xp_bar)

	_xp_label = Label.new()
	_xp_label.add_theme_font_size_override("font_size", 11)
	_xp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xp_row.add_child(_xp_label)

	# Level + SP
	_level_label = Label.new()
	_level_label.add_theme_font_size_override("font_size", 14)
	_level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_left.add_child(_level_label)

	# Bottom-left: Money, items, rent
	var bottom_left := VBoxContainer.new()
	bottom_left.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bottom_left.position = Vector2(10, -80)
	bottom_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom_left)

	_money_label = Label.new()
	_money_label.add_theme_font_size_override("font_size", 14)
	_money_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	_money_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_left.add_child(_money_label)

	_item_count_label = Label.new()
	_item_count_label.add_theme_font_size_override("font_size", 12)
	_item_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_left.add_child(_item_count_label)

	_rent_label = Label.new()
	_rent_label.add_theme_font_size_override("font_size", 11)
	_rent_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.6))
	_rent_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_left.add_child(_rent_label)

	# SP indicator (shown when skill points available)
	_sp_label = Label.new()
	_sp_label.add_theme_font_size_override("font_size", 12)
	_sp_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
	_sp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_left.add_child(_sp_label)


func _process(_delta: float) -> void:
	_update_health()
	_update_stamina()
	_update_xp()
	_update_info()


func _update_health() -> void:
	var player_node = PlayerManager.get_player_node(_player_id)
	if player_node == null:
		return
	var hc = player_node.get_node_or_null("HealthComponent")
	if hc == null:
		return
	_health_bar.max_value = hc.max_health
	_health_bar.value = hc.current_health
	_health_label.text = " %.0f/%.0f" % [hc.current_health, hc.max_health]


func _update_stamina() -> void:
	var player_node = PlayerManager.get_player_node(_player_id)
	if player_node == null:
		return
	var sc = player_node.get_node_or_null("StaminaComponent")
	if sc == null:
		return
	_stamina_bar.max_value = sc.max_stamina
	_stamina_bar.value = sc.current_stamina
	_stamina_label.text = " %.0f/%.0f" % [sc.current_stamina, sc.max_stamina]


func _update_xp() -> void:
	var level := PlayerManager.get_level(_player_id)
	var xp := PlayerManager.get_xp(_player_id)
	var max_level: int = DataManager.get_config_value("max_player_level_demo", 5)

	if level >= max_level:
		_xp_bar.max_value = 1
		_xp_bar.value = 1
		_xp_label.text = " MAX"
	else:
		var xp_needed := PlayerManager.get_xp_for_next_level(level)
		_xp_bar.max_value = xp_needed
		_xp_bar.value = xp
		_xp_label.text = " %d/%d" % [xp, xp_needed]

	_level_label.text = "Lv %d" % level


func _update_info() -> void:
	var money := EconomyManager.get_money(_player_id)
	_money_label.text = "$ %d" % money

	var items := InventoryManager.get_inventory_count(_player_id)
	_item_count_label.text = "Items: %d" % items

	var rent := EconomyManager.get_effective_rent(_player_id)
	_rent_label.text = "Rent: %d/week" % rent

	var sp := PlayerManager.get_skill_points(_player_id)
	if sp > 0:
		_sp_label.text = "Skill Points: %d [K]" % sp
		_sp_label.visible = true
	else:
		_sp_label.visible = false
