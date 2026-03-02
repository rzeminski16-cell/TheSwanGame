extends Node2D
## TestPlayground — Development testing scene.
## Spawns a player and debug overlay for Phase 1-2 verification.
## Debug keys: F1 +XP, F2 -HP, F3 overlay, F4 spawn rat, F5 spawn crab,
##             F6 spawn boss, F7 give random item, F8 clear enemies

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
	print("  F1: +50 XP | F2: -10 HP | F3: Debug overlay")
	print("  F4: Spawn Cave Rat | F5: Spawn Spitter Crab | F6: Spawn Crab King")
	print("  F7: Give random item | F8: Clear all enemies")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				PlayerManager.add_xp(1, 50)
				print("TestPlayground: Added 50 XP")
			KEY_F2:
				var player = PlayerManager.get_player_node(1)
				if player:
					var hc = player.get_node_or_null("HealthComponent")
					if hc:
						hc.take_damage(10.0)
						print("TestPlayground: Dealt 10 damage (HP: %.0f/%.0f)" % [hc.current_health, hc.max_health])
			KEY_F4:
				_spawn_test_enemy("melee_rat")
			KEY_F5:
				_spawn_test_enemy("ranged_crab")
			KEY_F6:
				_spawn_test_enemy("crab_king")
			KEY_F7:
				_give_random_item()
			KEY_F8:
				CombatManager.clear_all_enemies()
				print("TestPlayground: Cleared all enemies")


func _spawn_test_enemy(enemy_id: String) -> void:
	# Spawn at random position near edges (not on top of player)
	var spawn_pos := Vector2.ZERO
	var side := randi() % 4
	match side:
		0: spawn_pos = Vector2(randf_range(100, 1180), 80)       # Top
		1: spawn_pos = Vector2(randf_range(100, 1180), 640)      # Bottom
		2: spawn_pos = Vector2(80, randf_range(100, 620))        # Left
		3: spawn_pos = Vector2(1200, randf_range(100, 620))      # Right

	var enemy = CombatManager.spawn_enemy(enemy_id, spawn_pos, {}, self)
	if enemy:
		print("TestPlayground: Spawned %s at %s (Active: %d)" % [enemy_id, spawn_pos, CombatManager.get_active_enemy_count()])


func _give_random_item() -> void:
	var all_items: Array = DataManager.get_all_items()
	if all_items.is_empty():
		return
	var item: Dictionary = all_items[randi() % all_items.size()]
	var item_id: String = item.get("id", "")
	if InventoryManager.add_item(1, item_id):
		print("TestPlayground: Gave item '%s' to player 1" % item.get("display_name", item_id))
