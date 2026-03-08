extends Node
## AudioManager — BGM and SFX management.
## Child of Main.tscn (not an autoload).
## Uses procedural audio for placeholder sounds (no asset files needed).
## Volume levels: 0.0 (silent) to 1.0 (full).

signal bgm_changed(track_name: String)
signal sfx_played(sfx_name: String)

const BGM_CROSSFADE_DURATION := 1.0  # seconds
const MAX_SFX_PLAYERS := 8           # polyphony limit

var _bgm_player_a: AudioStreamPlayer
var _bgm_player_b: AudioStreamPlayer
var _active_bgm_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0

var _current_bgm: String = ""
var _crossfade_tween: Tween = null

var master_volume: float = 0.8
var bgm_volume: float = 0.5
var sfx_volume: float = 0.7
var _muted: bool = false


func _ready() -> void:
	# Create BGM players for crossfading
	_bgm_player_a = AudioStreamPlayer.new()
	_bgm_player_a.bus = "Master"
	add_child(_bgm_player_a)

	_bgm_player_b = AudioStreamPlayer.new()
	_bgm_player_b.bus = "Master"
	add_child(_bgm_player_b)

	_active_bgm_player = _bgm_player_a

	# Create SFX player pool
	for i in range(MAX_SFX_PLAYERS):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_sfx_players.append(player)

	_apply_volumes()
	print("AudioManager: Ready.")


# --- BGM ---

func play_bgm(track_name: String) -> void:
	if track_name == _current_bgm:
		return
	if _muted:
		_current_bgm = track_name
		return

	var stream := _get_bgm_stream(track_name)
	if stream == null:
		return

	# Crossfade
	var old_player := _active_bgm_player
	var new_player := _bgm_player_b if _active_bgm_player == _bgm_player_a else _bgm_player_a
	_active_bgm_player = new_player

	new_player.stream = stream
	new_player.volume_db = -80.0
	new_player.play()

	if _crossfade_tween:
		_crossfade_tween.kill()
	_crossfade_tween = create_tween()
	_crossfade_tween.set_parallel(true)
	_crossfade_tween.tween_property(new_player, "volume_db", _bgm_db(), BGM_CROSSFADE_DURATION)
	_crossfade_tween.tween_property(old_player, "volume_db", -80.0, BGM_CROSSFADE_DURATION)
	_crossfade_tween.chain().tween_callback(old_player.stop)

	_current_bgm = track_name
	bgm_changed.emit(track_name)
	print("AudioManager: BGM → '%s'" % track_name)


func stop_bgm() -> void:
	if _crossfade_tween:
		_crossfade_tween.kill()
	_crossfade_tween = create_tween()
	_crossfade_tween.tween_property(_active_bgm_player, "volume_db", -80.0, 0.5)
	_crossfade_tween.chain().tween_callback(_active_bgm_player.stop)
	_current_bgm = ""


func get_current_bgm() -> String:
	return _current_bgm


# --- SFX ---

func play_sfx(sfx_name: String) -> void:
	if _muted:
		return

	var stream := _get_sfx_stream(sfx_name)
	if stream == null:
		return

	# Round-robin through SFX player pool
	var player := _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_players.size()

	player.stream = stream
	player.volume_db = _sfx_db()
	player.play()

	sfx_played.emit(sfx_name)


# --- Volume ---

func set_master_volume(vol: float) -> void:
	master_volume = clampf(vol, 0.0, 1.0)
	_apply_volumes()


func set_bgm_volume(vol: float) -> void:
	bgm_volume = clampf(vol, 0.0, 1.0)
	_apply_volumes()


func set_sfx_volume(vol: float) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)
	_apply_volumes()


func toggle_mute() -> void:
	_muted = not _muted
	if _muted:
		_active_bgm_player.volume_db = -80.0
	else:
		_apply_volumes()
		if _current_bgm != "":
			_active_bgm_player.volume_db = _bgm_db()


func is_muted() -> bool:
	return _muted


# --- Volume Helpers ---

func _bgm_db() -> float:
	return linear_to_db(master_volume * bgm_volume)


func _sfx_db() -> float:
	return linear_to_db(master_volume * sfx_volume)


func _apply_volumes() -> void:
	if _active_bgm_player and _active_bgm_player.playing:
		_active_bgm_player.volume_db = _bgm_db()


# --- Procedural Audio Streams ---
# These generate placeholder sounds so the game has audio feedback
# without needing actual .wav/.ogg files. Replace with real assets later.

func _get_bgm_stream(track_name: String) -> AudioStream:
	# Try loading from file first
	var path := "res://audio/bgm/%s.ogg" % track_name
	if ResourceLoader.exists(path):
		return load(path)
	# Fall back to procedural tone
	return _generate_tone_stream(track_name)


func _get_sfx_stream(sfx_name: String) -> AudioStream:
	# Try loading from file first
	var path := "res://audio/sfx/%s.wav" % sfx_name
	if ResourceLoader.exists(path):
		return load(path)
	# Fall back to procedural sound
	return _generate_sfx_stream(sfx_name)


func _generate_tone_stream(track_name: String) -> AudioStream:
	## Generates a simple procedural tone as BGM placeholder.
	var sample_rate := 22050
	var duration := 4.0
	var samples := int(sample_rate * duration)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = samples

	var base_freq := 220.0
	match track_name:
		"overworld": base_freq = 261.63
		"dungeon": base_freq = 196.0
		"boss": base_freq = 164.81
		"menu": base_freq = 329.63
		"night": base_freq = 220.0

	var data := PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t := float(i) / sample_rate
		var env := minf(1.0, t * 4.0) * 0.15
		var val := sin(t * base_freq * TAU) * env
		val += sin(t * base_freq * 1.5 * TAU) * env * 0.3
		data[i] = int((val + 1.0) * 0.5 * 255.0)

	stream.data = data
	return stream


func _generate_sfx_stream(sfx_name: String) -> AudioStream:
	## Generates a simple procedural SFX placeholder.
	var sample_rate := 22050
	var duration := 0.15
	var freq := 440.0
	var decay := 10.0

	match sfx_name:
		"hit": freq = 200.0; duration = 0.12; decay = 15.0
		"crit": freq = 350.0; duration = 0.15; decay = 12.0
		"dodge": freq = 600.0; duration = 0.1; decay = 20.0
		"pickup": freq = 880.0; duration = 0.1; decay = 18.0
		"money": freq = 1046.5; duration = 0.08; decay = 25.0
		"level_up": freq = 523.25; duration = 0.3; decay = 5.0
		"death": freq = 110.0; duration = 0.4; decay = 4.0
		"button": freq = 660.0; duration = 0.05; decay = 30.0
		"save": freq = 440.0; duration = 0.2; decay = 8.0
		"error": freq = 150.0; duration = 0.2; decay = 10.0
		"dungeon_enter": freq = 196.0; duration = 0.3; decay = 5.0
		"dungeon_clear": freq = 523.25; duration = 0.25; decay = 6.0
		"room_clear": freq = 440.0; duration = 0.15; decay = 10.0
		"enemy_die": freq = 250.0; duration = 0.1; decay = 18.0
		"rent_paid": freq = 660.0; duration = 0.15; decay = 12.0

	var samples := int(sample_rate * duration)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED

	var data := PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t := float(i) / sample_rate
		var env := exp(-t * decay)
		var val := sin(t * freq * TAU) * env * 0.4
		data[i] = int((val + 1.0) * 0.5 * 255.0)

	stream.data = data
	return stream
