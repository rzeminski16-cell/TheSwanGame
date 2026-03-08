extends PanelContainer
## DialogueBox — Bottom-screen dialogue panel for cutscenes and NPC chat.
## Shows speaker name, text (typewriter effect), and advance prompt.

signal dialogue_advanced()
signal dialogue_finished()

var _speaker_label: Label
var _text_label: RichTextLabel
var _advance_label: Label

var _full_text: String = ""
var _char_index: int = 0
var _typing: bool = false
var _chars_per_second: float = 40.0
var _timer: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(900, 120)
	size = Vector2(900, 120)
	var vp_size := get_viewport_rect().size
	position = Vector2((vp_size.x - 900) / 2.0, vp_size.y - 140)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_build_ui()


func _build_ui() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.02, 0.02, 0.05, 0.95)
	bg.border_color = Color(0.4, 0.4, 0.6)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(8)
	bg.set_content_margin_all(16)
	add_theme_stylebox_override("panel", bg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)

	# Speaker name
	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", 16)
	_speaker_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(_speaker_label)

	# Dialogue text
	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = false
	_text_label.scroll_active = false
	_text_label.fit_content = true
	_text_label.custom_minimum_size = Vector2(860, 50)
	_text_label.add_theme_font_size_override("normal_font_size", 14)
	vbox.add_child(_text_label)

	# Advance prompt
	_advance_label = Label.new()
	_advance_label.text = "[Press E or Click to continue]"
	_advance_label.add_theme_font_size_override("font_size", 11)
	_advance_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	_advance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_advance_label.visible = false
	vbox.add_child(_advance_label)


func show_line(speaker: String, text: String) -> void:
	## Display a new dialogue line with typewriter effect.
	_speaker_label.text = speaker
	_full_text = text
	_char_index = 0
	_text_label.text = ""
	_typing = true
	_timer = 0.0
	_advance_label.visible = false
	visible = true


func _process(delta: float) -> void:
	if not _typing:
		return

	_timer += delta
	var chars_to_show := int(_timer * _chars_per_second)
	if chars_to_show > _char_index:
		_char_index = mini(chars_to_show, _full_text.length())
		_text_label.text = _full_text.substr(0, _char_index)

	if _char_index >= _full_text.length():
		_typing = false
		_advance_label.visible = true


func _input(event: InputEvent) -> void:
	if not visible:
		return

	var advance := false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E or event.physical_keycode == KEY_SPACE or event.physical_keycode == KEY_ENTER:
			advance = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance = true

	if advance:
		get_viewport().set_input_as_handled()
		if _typing:
			# Skip typewriter, show full text
			_char_index = _full_text.length()
			_text_label.text = _full_text
			_typing = false
			_advance_label.visible = true
		else:
			dialogue_advanced.emit()


func hide_dialogue() -> void:
	visible = false
	_typing = false
