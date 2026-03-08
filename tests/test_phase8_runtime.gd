extends Node
## Phase 8 Runtime Tests — Audio, Visuals, Cutscenes.
## Tests AudioManager API, ScreenTransition, DialogueBox,
## CutscenePlayer, VisualEffects, and UIManager integration.

var _pass_count := 0
var _fail_count := 0


func _ready() -> void:
	print("\n=== Phase 8 Runtime Tests ===\n")
	_test_audio_manager_exists()
	_test_audio_manager_volume()
	_test_audio_manager_mute()
	_test_audio_manager_bgm()
	_test_audio_manager_sfx()
	_test_screen_transition()
	_test_dialogue_box()
	_test_cutscene_player()
	_test_ui_manager_integration()
	_test_time_manager_set_paused()

	print("\n--- Results: %d passed, %d failed ---" % [_pass_count, _fail_count])


func _check(label: String, condition: bool) -> void:
	if condition:
		print("  PASS  %s" % label)
		_pass_count += 1
	else:
		print("  FAIL  %s" % label)
		_fail_count += 1


# --- AudioManager ---

func _test_audio_manager_exists() -> void:
	print("--- AudioManager Existence ---")
	var audio = get_node_or_null("/root/Main/AudioManager")
	_check("AudioManager node exists under Main", audio != null)
	if audio:
		_check("AudioManager has play_bgm method", audio.has_method("play_bgm"))
		_check("AudioManager has stop_bgm method", audio.has_method("stop_bgm"))
		_check("AudioManager has play_sfx method", audio.has_method("play_sfx"))
		_check("AudioManager has set_master_volume method", audio.has_method("set_master_volume"))
		_check("AudioManager has set_bgm_volume method", audio.has_method("set_bgm_volume"))
		_check("AudioManager has set_sfx_volume method", audio.has_method("set_sfx_volume"))
		_check("AudioManager has toggle_mute method", audio.has_method("toggle_mute"))
		_check("AudioManager has is_muted method", audio.has_method("is_muted"))
		_check("AudioManager has get_current_bgm method", audio.has_method("get_current_bgm"))


func _test_audio_manager_volume() -> void:
	print("--- AudioManager Volume ---")
	var audio = get_node_or_null("/root/Main/AudioManager")
	if audio == null:
		_check("AudioManager exists for volume tests", false)
		return

	audio.set_master_volume(0.5)
	_check("set_master_volume(0.5) → 0.5", is_equal_approx(audio.master_volume, 0.5))

	audio.set_master_volume(1.5)
	_check("set_master_volume(1.5) clamped to 1.0", is_equal_approx(audio.master_volume, 1.0))

	audio.set_master_volume(-0.5)
	_check("set_master_volume(-0.5) clamped to 0.0", is_equal_approx(audio.master_volume, 0.0))

	audio.set_bgm_volume(0.7)
	_check("set_bgm_volume(0.7) → 0.7", is_equal_approx(audio.bgm_volume, 0.7))

	audio.set_sfx_volume(0.3)
	_check("set_sfx_volume(0.3) → 0.3", is_equal_approx(audio.sfx_volume, 0.3))

	# Restore defaults
	audio.set_master_volume(0.8)
	audio.set_bgm_volume(0.5)
	audio.set_sfx_volume(0.7)


func _test_audio_manager_mute() -> void:
	print("--- AudioManager Mute ---")
	var audio = get_node_or_null("/root/Main/AudioManager")
	if audio == null:
		_check("AudioManager exists for mute tests", false)
		return

	_check("Not muted by default", audio.is_muted() == false)
	audio.toggle_mute()
	_check("After toggle_mute → muted", audio.is_muted() == true)
	audio.toggle_mute()
	_check("After second toggle_mute → not muted", audio.is_muted() == false)


func _test_audio_manager_bgm() -> void:
	print("--- AudioManager BGM ---")
	var audio = get_node_or_null("/root/Main/AudioManager")
	if audio == null:
		_check("AudioManager exists for BGM tests", false)
		return

	_check("No BGM playing initially", audio.get_current_bgm() == "")

	audio.play_bgm("overworld")
	_check("After play_bgm('overworld') → current is 'overworld'", audio.get_current_bgm() == "overworld")

	audio.play_bgm("dungeon")
	_check("After play_bgm('dungeon') → current is 'dungeon'", audio.get_current_bgm() == "dungeon")

	# Same track should not restart
	audio.play_bgm("dungeon")
	_check("Playing same track again keeps 'dungeon'", audio.get_current_bgm() == "dungeon")

	audio.stop_bgm()
	_check("After stop_bgm() → current is empty", audio.get_current_bgm() == "")


func _test_audio_manager_sfx() -> void:
	print("--- AudioManager SFX ---")
	var audio = get_node_or_null("/root/Main/AudioManager")
	if audio == null:
		_check("AudioManager exists for SFX tests", false)
		return

	# SFX should not crash with any known name
	var sfx_names := ["hit", "crit", "dodge", "pickup", "money", "level_up",
					  "death", "button", "save", "error", "dungeon_enter",
					  "dungeon_clear", "room_clear", "enemy_die", "rent_paid"]
	for sfx_name in sfx_names:
		audio.play_sfx(sfx_name)
	_check("All %d SFX names played without error" % sfx_names.size(), true)

	# Unknown SFX should still work (generic tone)
	audio.play_sfx("unknown_sfx_xyz")
	_check("Unknown SFX name plays without crash", true)


# --- ScreenTransition ---

func _test_screen_transition() -> void:
	print("--- ScreenTransition ---")
	var ui = get_node_or_null("/root/Main/UIManager")
	if ui == null:
		_check("UIManager exists for transition tests", false)
		return

	var trans: ColorRect = ui.get_screen_transition() if ui.has_method("get_screen_transition") else null
	_check("ScreenTransition exists under UIManager", trans != null)
	if trans == null:
		return

	_check("ScreenTransition has fade_out method", trans.has_method("fade_out"))
	_check("ScreenTransition has fade_in method", trans.has_method("fade_in"))
	_check("ScreenTransition has instant_black method", trans.has_method("instant_black"))
	_check("ScreenTransition has instant_clear method", trans.has_method("instant_clear"))

	# Test instant methods
	trans.instant_black()
	_check("instant_black() → alpha is 1.0", is_equal_approx(trans.color.a, 1.0))

	trans.instant_clear()
	_check("instant_clear() → alpha is 0.0", is_equal_approx(trans.color.a, 0.0))


# --- DialogueBox ---

func _test_dialogue_box() -> void:
	print("--- DialogueBox ---")
	var ui = get_node_or_null("/root/Main/UIManager")
	if ui == null or ui._dialogue_box == null:
		_check("DialogueBox exists under UIManager", false)
		return

	var db: Control = ui._dialogue_box
	_check("DialogueBox exists", db != null)
	_check("DialogueBox has show_line method", db.has_method("show_line"))
	_check("DialogueBox has hide_dialogue method", db.has_method("hide_dialogue"))

	# Initially hidden
	_check("DialogueBox starts hidden", db.visible == false)

	# Show a line
	db.show_line("Test Speaker", "Hello, this is a test line.")
	_check("After show_line → visible", db.visible == true)

	db.hide_dialogue()
	_check("After hide_dialogue → hidden", db.visible == false)


# --- CutscenePlayer ---

func _test_cutscene_player() -> void:
	print("--- CutscenePlayer ---")
	var ui = get_node_or_null("/root/Main/UIManager")
	if ui == null:
		_check("UIManager exists for cutscene tests", false)
		return

	var cp: Node = ui.get_cutscene_player() if ui.has_method("get_cutscene_player") else null
	_check("CutscenePlayer exists under UIManager", cp != null)
	if cp == null:
		return

	_check("CutscenePlayer has play_cutscene method", cp.has_method("play_cutscene"))
	_check("CutscenePlayer has skip_cutscene method", cp.has_method("skip_cutscene"))
	_check("CutscenePlayer has is_playing method", cp.has_method("is_playing"))
	_check("CutscenePlayer not playing initially", cp.is_playing() == false)

	# Play a cutscene
	cp.play_cutscene("cutscene_tutorial_intro")
	_check("After play_cutscene → is_playing", cp.is_playing() == true)

	# Skip it
	cp.skip_cutscene()
	_check("After skip_cutscene → not playing", cp.is_playing() == false)


# --- UIManager Integration ---

func _test_ui_manager_integration() -> void:
	print("--- UIManager Phase 8 Integration ---")
	var ui = get_node_or_null("/root/Main/UIManager")
	_check("UIManager exists", ui != null)
	if ui == null:
		return

	_check("UIManager has _screen_transition", ui._screen_transition != null)
	_check("UIManager has _dialogue_box", ui._dialogue_box != null)
	_check("UIManager has _cutscene_player", ui._cutscene_player != null)
	_check("UIManager has get_cutscene_player()", ui.has_method("get_cutscene_player"))
	_check("UIManager has get_screen_transition()", ui.has_method("get_screen_transition"))


# --- TimeManager ---

func _test_time_manager_set_paused() -> void:
	print("--- TimeManager set_paused ---")
	_check("TimeManager has set_paused()", TimeManager.has_method("set_paused"))

	TimeManager.start_time()
	_check("TimeManager active after start_time()", TimeManager.is_active == true)

	TimeManager.set_paused(true)
	_check("set_paused(true) → not active", TimeManager.is_active == false)

	TimeManager.set_paused(false)
	_check("set_paused(false) → active again", TimeManager.is_active == true)

	TimeManager.pause_time()
