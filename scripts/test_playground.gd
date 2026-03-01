extends Node2D
## TestPlayground — Development testing scene.
## Spawns a player and debug overlay for Phase 1 verification.


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

	print("TestPlayground: Ready. Use WASD to move. F3 toggles debug overlay.")


func _input(event: InputEvent) -> void:
	# Debug key: F1 = add 50 XP
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			PlayerManager.add_xp(1, 50)
			print("TestPlayground: Added 50 XP")
		# Debug key: F2 = deal 10 damage to player
		elif event.keycode == KEY_F2:
			var player = PlayerManager.get_player_node(1)
			if player:
				var hc = player.get_node_or_null("HealthComponent")
				if hc:
					hc.take_damage(10.0)
					print("TestPlayground: Dealt 10 damage (HP: %.0f/%.0f)" % [hc.current_health, hc.max_health])
