extends PanelContainer
## GameOverScreen — Shown on player death outside dungeons.
## Offers Load Save or Main Menu options.

signal load_save_pressed()
signal main_menu_pressed()

var _load_btn: Button


func _ready() -> void:
	custom_minimum_size = Vector2(380, 280)
	size = Vector2(380, 280)
	var vp_size := get_viewport_rect().size
	position = Vector2((vp_size.x - 380) / 2.0, (vp_size.y - 280) / 2.0)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_build_ui()


func _build_ui() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.02, 0.02, 0.96)
	bg.border_color = Color(0.7, 0.2, 0.2)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(10)
	bg.set_content_margin_all(24)
	add_theme_stylebox_override("panel", bg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "YOU DIED"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Message
	var msg := Label.new()
	msg.text = "Death penalty applied.\nYou lost some money and items."
	msg.add_theme_font_size_override("font_size", 13)
	msg.add_theme_color_override("font_color", Color(0.7, 0.5, 0.5))
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(msg)

	vbox.add_child(HSeparator.new())

	# Load Save button
	_load_btn = Button.new()
	_load_btn.text = "Load Save"
	_load_btn.custom_minimum_size = Vector2(220, 40)
	_load_btn.pressed.connect(func(): load_save_pressed.emit())
	_load_btn.disabled = not SaveManager.has_save()
	vbox.add_child(_load_btn)

	# Main Menu button
	var menu_btn := Button.new()
	menu_btn.text = "Main Menu"
	menu_btn.custom_minimum_size = Vector2(220, 40)
	menu_btn.pressed.connect(func(): main_menu_pressed.emit())
	vbox.add_child(menu_btn)
