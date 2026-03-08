extends Node
## CutscenePlayer — Plays scripted cutscene sequences from cutscenes.json.
## Pauses game time, shows dialogue box, and emits completion signal.

signal cutscene_started(cutscene_id: String)
signal cutscene_finished(cutscene_id: String)

var _dialogue_box: Control = null
var _current_cutscene_id: String = ""
var _lines: Array = []
var _line_index: int = 0
var _playing: bool = false


func _ready() -> void:
	print("CutscenePlayer: Ready.")


func set_dialogue_box(box: Control) -> void:
	## Must be called with a DialogueBox instance before playing cutscenes.
	if _dialogue_box and _dialogue_box.dialogue_advanced.is_connected(_on_advance):
		_dialogue_box.dialogue_advanced.disconnect(_on_advance)
	_dialogue_box = box
	_dialogue_box.dialogue_advanced.connect(_on_advance)


func play_cutscene(cutscene_id: String) -> void:
	## Start playing a cutscene by its ID from cutscenes.json.
	if _playing:
		push_warning("CutscenePlayer: Already playing '%s', ignoring '%s'" % [_current_cutscene_id, cutscene_id])
		return

	var cutscene_data: Dictionary = _load_cutscene(cutscene_id)
	if cutscene_data.is_empty():
		push_warning("CutscenePlayer: Cutscene '%s' not found." % cutscene_id)
		return

	if not _dialogue_box:
		push_warning("CutscenePlayer: No dialogue box set.")
		return

	_current_cutscene_id = cutscene_id
	_lines = cutscene_data.get("lines", [])
	_line_index = 0
	_playing = true

	# Pause time during cutscene
	if TimeManager:
		TimeManager.set_paused(true)

	cutscene_started.emit(cutscene_id)
	_show_current_line()
	print("CutscenePlayer: Playing '%s' (%d lines)" % [cutscene_id, _lines.size()])


func is_playing() -> bool:
	return _playing


func skip_cutscene() -> void:
	## Skip remaining lines and finish.
	if _playing:
		_finish()


func _show_current_line() -> void:
	if _line_index >= _lines.size():
		_finish()
		return

	var line: Dictionary = _lines[_line_index]
	var speaker: String = line.get("speaker", "")
	var text: String = line.get("text", "")
	_dialogue_box.show_line(speaker, text)


func _on_advance() -> void:
	if not _playing:
		return
	_line_index += 1
	_show_current_line()


func _finish() -> void:
	_playing = false
	_dialogue_box.hide_dialogue()

	# Resume time
	if TimeManager:
		TimeManager.set_paused(false)

	var finished_id := _current_cutscene_id
	_current_cutscene_id = ""
	_lines = []
	_line_index = 0
	cutscene_finished.emit(finished_id)
	print("CutscenePlayer: Finished '%s'" % finished_id)


func _load_cutscene(cutscene_id: String) -> Dictionary:
	## Load cutscene data from the JSON file.
	var path := "res://data/cutscenes.json"
	if not FileAccess.file_exists(path):
		push_warning("CutscenePlayer: cutscenes.json not found.")
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_warning("CutscenePlayer: JSON parse error.")
		return {}

	var all_cutscenes: Dictionary = json.data
	if all_cutscenes.has(cutscene_id):
		return all_cutscenes[cutscene_id]
	return {}
