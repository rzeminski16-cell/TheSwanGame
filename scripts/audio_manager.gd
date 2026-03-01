extends Node
## AudioManager — BGM and SFX management.
## Child of Main.tscn (not an autoload).
## Full implementation in Phase 8.


func _ready() -> void:
	print("AudioManager: Ready.")


func play_bgm(_track_name: String) -> void:
	# Phase 8: Play background music
	pass


func stop_bgm() -> void:
	# Phase 8: Stop current music
	pass


func play_sfx(_sfx_name: String) -> void:
	# Phase 8: Play sound effect
	pass
