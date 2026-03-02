extends PanelContainer
## InventoryPanel — Shows player's held items with their effects.
## Toggle with I key.

signal closed()

var _player_id: int = 1
var _item_list: VBoxContainer
var _title_label: Label
var _count_label: Label

const RARITY_COLORS := {
	"common": Color(0.7, 0.7, 0.7),
	"rare": Color(0.3, 0.5, 1.0),
	"epic": Color(0.7, 0.3, 1.0),
}


func _ready() -> void:
	custom_minimum_size = Vector2(350, 400)
	set_anchors_preset(Control.PRESET_CENTER)
	_build_ui()
	_refresh()

	InventoryManager.item_added.connect(_on_item_changed)
	InventoryManager.item_removed.connect(_on_item_changed)


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

	_title_label = Label.new()
	_title_label.text = "INVENTORY"
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)

	_count_label = Label.new()
	_count_label.add_theme_font_size_override("font_size", 14)
	_count_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	header.add_child(_count_label)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(30, 30)
	close_btn.pressed.connect(_on_close_pressed)
	header.add_child(close_btn)

	var sep := HSeparator.new()
	root.add_child(sep)

	# Scrollable item list
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	_item_list = VBoxContainer.new()
	_item_list.add_theme_constant_override("separation", 4)
	_item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_item_list)

	# Footer hint
	var hint := Label.new()
	hint.text = "Press I to close"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hint)


func _refresh() -> void:
	# Clear existing
	for child in _item_list.get_children():
		child.queue_free()

	var inventory: Array = InventoryManager.get_inventory(_player_id)
	_count_label.text = "%d items" % inventory.size()

	if inventory.is_empty():
		var empty := Label.new()
		empty.text = "No items yet."
		empty.add_theme_font_size_override("font_size", 13)
		empty.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_item_list.add_child(empty)
		return

	# Count duplicates
	var item_counts: Dictionary = {}
	for item_id in inventory:
		item_counts[item_id] = item_counts.get(item_id, 0) + 1

	for item_id in item_counts:
		var item_data: Dictionary = DataManager.get_item(item_id)
		if item_data.is_empty():
			continue

		var count: int = item_counts[item_id]
		var row := _create_item_row(item_data, count)
		_item_list.add_child(row)


func _create_item_row(item_data: Dictionary, count: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.18)
	style.set_border_width_all(1)
	var rarity: String = item_data.get("rarity", "common")
	style.border_color = RARITY_COLORS.get(rarity, Color(0.3, 0.3, 0.3))
	style.set_corner_radius_all(4)
	style.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	# Name + count
	var name_label := Label.new()
	var display_name: String = item_data.get("display_name", item_data.get("id", "?"))
	if count > 1:
		name_label.text = "%s x%d" % [display_name, count]
	else:
		name_label.text = display_name
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", RARITY_COLORS.get(rarity, Color.WHITE))
	vbox.add_child(name_label)

	# Effects
	var effects: Array = item_data.get("effects", [])
	for effect in effects:
		var stat: String = effect.get("stat", "")
		var mod_type: String = effect.get("modifier_type", "")
		var value: float = float(effect.get("value", 0))

		var effect_text := ""
		if mod_type == "percent":
			if value >= 0:
				effect_text = "+%.0f%% %s" % [value * 100, stat.replace("_", " ")]
			else:
				effect_text = "%.0f%% %s" % [value * 100, stat.replace("_", " ")]
		else:
			if value >= 0:
				effect_text = "+%.0f %s" % [value, stat.replace("_", " ")]
			else:
				effect_text = "%.0f %s" % [value, stat.replace("_", " ")]

		var effect_label := Label.new()
		effect_label.text = effect_text
		effect_label.add_theme_font_size_override("font_size", 11)
		if value >= 0:
			effect_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
		else:
			effect_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
		vbox.add_child(effect_label)

	return panel


func _on_item_changed(_pid: int, _item_id: String) -> void:
	_refresh()


func _on_close_pressed() -> void:
	closed.emit()
