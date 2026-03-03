extends Node2D
## TestPlayground — Development testing scene.
## Spawns a player and debug overlay for testing.
## All debug actions are now in the Debug Menu (F3).

func _ready() -> void:
	# Spawn player at center
	var player = PlayerManager.spawn_player(1, self)
	if player:
		player.position = Vector2(640, 360)

	# Add debug overlay
	var overlay_scene := load("res://scenes/ui/DebugOverlay.tscn") as PackedScene
	if overlay_scene:
		var overlay := overlay_scene.instantiate()
		add_child(overlay)

	print("TestPlayground: Ready. WASD to move. Left-click to shoot.")
	print("  F3: Debug Menu | I: Inventory | K: Skill Tree | ESC: Pause")
