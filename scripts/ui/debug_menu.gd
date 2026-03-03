extends PanelContainer
## DebugMenu — Categorized debug panel that replaces hotkey-based debug inputs.
## Toggle with F3. Groups debug actions by category.
## Categories: Player, Combat, Economy, Time, Missions, Scenes.

signal closed()

var _content: VBoxContainer
var _category_containers: Dictionary = {}  # category_name → VBoxContainer


func _ready() -> void:
	custom_minimum_size = Vector2(280, 500)
	size = Vector2(280, 500)
	# Position on the right side of the viewport, vertically centered
	var vp_size := get_viewport_rect().size
	position = Vector2(vp_size.x - 300, (vp_size.y - 500) / 2.0)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_build_ui()


func _build_ui() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.06, 0.06, 0.09, 0.95)
	bg.border_color = Color(0.4, 0.4, 0.5)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(8)
	bg.set_content_margin_all(12)
	add_theme_stylebox_override("panel", bg)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(260, 480)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 4)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_content)

	# Title
	var title := Label.new()
	title.text = "DEBUG MENU"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(title)

	var sep := HSeparator.new()
	_content.add_child(sep)

	# --- Player Category ---
	_add_category("Player")
	_add_button("Player", "+50 XP", _on_add_xp)
	_add_button("Player", "+500 XP", _on_add_xp_big)
	_add_button("Player", "Level Up", _on_level_up)
	_add_button("Player", "Heal Full", _on_heal_full)
	_add_button("Player", "-10 HP", _on_damage_self)
	_add_button("Player", "Kill Player", _on_kill_player)
	_add_button("Player", "Give Random Item", _on_give_item)
	_add_button("Player", "Clear Inventory", _on_clear_inventory)

	# --- Combat Category ---
	_add_category("Combat")
	_add_button("Combat", "Spawn Cave Rat", _on_spawn_rat)
	_add_button("Combat", "Spawn Spitter Crab", _on_spawn_crab)
	_add_button("Combat", "Spawn Crab King", _on_spawn_boss)
	_add_button("Combat", "Clear All Enemies", _on_clear_enemies)

	# --- Economy Category ---
	_add_category("Economy")
	_add_button("Economy", "+100 Money", _on_add_money_100)
	_add_button("Economy", "+500 Money", _on_add_money_500)
	_add_button("Economy", "+2000 Money", _on_add_money_2000)
	_add_button("Economy", "Pay Rent", _on_pay_rent)

	# --- Time Category ---
	_add_category("Time")
	_add_button("Time", "Start/Resume Time", _on_start_time)
	_add_button("Time", "Pause Time", _on_pause_time)
	_add_button("Time", "Skip to Night", _on_skip_to_night)
	_add_button("Time", "Skip to Next Day", _on_skip_to_day)

	# --- Missions Category ---
	_add_category("Missions")
	_add_button("Missions", "Start Tutorial", _on_start_tutorial)
	_add_button("Missions", "Start Find Papers", _on_start_papers)
	_add_button("Missions", "Start First Delivery", _on_start_first_delivery)
	_add_button("Missions", "Start Crab Cave", _on_start_crab_cave_mission)
	_add_button("Missions", "Start Pay Rent", _on_start_pay_rent)
	_add_button("Missions", "Complete Current Obj", _on_complete_objective)

	# --- Scenes Category ---
	_add_category("Scenes")
	_add_button("Scenes", "Go to Overworld", _on_goto_overworld)
	_add_button("Scenes", "Go to Test Playground", _on_goto_playground)
	_add_button("Scenes", "Enter Crab Cave", _on_enter_crab_cave)
	_add_button("Scenes", "Enter Abandoned Tunnel", _on_enter_tunnel)
	_add_button("Scenes", "Start Delivery", _on_start_delivery)

	# Close button
	_content.add_child(HSeparator.new())
	var close_btn := Button.new()
	close_btn.text = "Close (F3)"
	close_btn.custom_minimum_size = Vector2(0, 30)
	close_btn.pressed.connect(func(): closed.emit())
	_content.add_child(close_btn)


func _add_category(category_name: String) -> void:
	var header := Button.new()
	header.text = "  %s" % category_name
	header.flat = true
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.custom_minimum_size = Vector2(0, 24)
	_content.add_child(header)

	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)
	_content.add_child(container)
	_category_containers[category_name] = container

	# Toggle collapse
	header.pressed.connect(func(): container.visible = not container.visible)


func _add_button(category: String, label: String, callback: Callable) -> void:
	var container: VBoxContainer = _category_containers.get(category)
	if container == null:
		return

	var btn := Button.new()
	btn.text = "    %s" % label
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 26)
	btn.add_theme_font_size_override("font_size", 12)
	btn.pressed.connect(callback)
	container.add_child(btn)


# --- Player Actions ---

func _on_add_xp() -> void:
	PlayerManager.add_xp(1, 50)
	print("DebugMenu: Added 50 XP")

func _on_add_xp_big() -> void:
	PlayerManager.add_xp(1, 500)
	print("DebugMenu: Added 500 XP")

func _on_level_up() -> void:
	var needed := PlayerManager.get_xp_for_next_level(PlayerManager.get_level(1))
	PlayerManager.add_xp(1, needed)
	print("DebugMenu: Force level up")

func _on_heal_full() -> void:
	var player = PlayerManager.get_player_node(1)
	if player:
		var hc = player.get_node_or_null("HealthComponent")
		if hc and hc.has_method("heal_full"):
			hc.heal_full()
			print("DebugMenu: Healed to full (HP: %.0f/%.0f)" % [hc.current_health, hc.max_health])

func _on_damage_self() -> void:
	var player = PlayerManager.get_player_node(1)
	if player:
		var hc = player.get_node_or_null("HealthComponent")
		if hc:
			hc.take_damage(10.0)
			print("DebugMenu: Dealt 10 damage (HP: %.0f/%.0f)" % [hc.current_health, hc.max_health])

func _on_kill_player() -> void:
	var player = PlayerManager.get_player_node(1)
	if player:
		var hc = player.get_node_or_null("HealthComponent")
		if hc:
			hc.take_damage(hc.current_health + 1)
			print("DebugMenu: Player killed")

func _on_give_item() -> void:
	var all_items: Array = DataManager.get_all_items()
	if all_items.is_empty():
		return
	var item: Dictionary = all_items[randi() % all_items.size()]
	var item_id: String = item.get("id", "")
	if InventoryManager.add_item(1, item_id):
		print("DebugMenu: Gave item '%s'" % item.get("display_name", item_id))

func _on_clear_inventory() -> void:
	InventoryManager.clear_inventory(1)
	print("DebugMenu: Cleared inventory")


# --- Combat Actions ---

func _on_spawn_rat() -> void:
	_spawn_debug_enemy("melee_rat")

func _on_spawn_crab() -> void:
	_spawn_debug_enemy("ranged_crab")

func _on_spawn_boss() -> void:
	_spawn_debug_enemy("crab_king")

func _on_clear_enemies() -> void:
	CombatManager.clear_all_enemies()
	print("DebugMenu: Cleared all enemies")

func _spawn_debug_enemy(enemy_id: String) -> void:
	var spawn_pos := Vector2.ZERO
	var side := randi() % 4
	match side:
		0: spawn_pos = Vector2(randf_range(100, 1180), 80)
		1: spawn_pos = Vector2(randf_range(100, 1180), 640)
		2: spawn_pos = Vector2(80, randf_range(100, 620))
		3: spawn_pos = Vector2(1200, randf_range(100, 620))

	var scene_parent := _get_scene_parent()
	var enemy = CombatManager.spawn_enemy(enemy_id, spawn_pos, {}, scene_parent)
	if enemy:
		print("DebugMenu: Spawned %s (Active: %d)" % [enemy_id, CombatManager.get_active_enemy_count()])


# --- Economy Actions ---

func _on_add_money_100() -> void:
	EconomyManager.add_money(1, 100)
	print("DebugMenu: Added 100 money")

func _on_add_money_500() -> void:
	EconomyManager.add_money(1, 500)
	print("DebugMenu: Added 500 money")

func _on_add_money_2000() -> void:
	EconomyManager.add_money(1, 2000)
	print("DebugMenu: Added 2000 money")

func _on_pay_rent() -> void:
	var success := EconomyManager.pay_rent(1)
	print("DebugMenu: Pay rent → %s" % ("success" if success else "failed"))


# --- Time Actions ---

func _on_start_time() -> void:
	if TimeManager.is_active:
		TimeManager.resume_time()
		print("DebugMenu: Time resumed")
	else:
		TimeManager.start_time()
		print("DebugMenu: Time started")

func _on_pause_time() -> void:
	TimeManager.pause_time()
	print("DebugMenu: Time paused")

func _on_skip_to_night() -> void:
	TimeManager.advance_to_night()
	print("DebugMenu: Skipped to night")

func _on_skip_to_day() -> void:
	TimeManager.advance_to_next_day()
	print("DebugMenu: Skipped to next day")


# --- Mission Actions ---

func _on_start_tutorial() -> void:
	MissionManager.start_mission("mission_tutorial")

func _on_start_papers() -> void:
	MissionManager.start_mission("mission_papers")

func _on_start_first_delivery() -> void:
	MissionManager.start_mission("mission_first_delivery")

func _on_start_crab_cave_mission() -> void:
	MissionManager.start_mission("mission_crab_cave")

func _on_start_pay_rent() -> void:
	MissionManager.start_mission("mission_pay_rent")

func _on_complete_objective() -> void:
	var active_id := MissionManager.get_active_mission_id()
	if active_id == "":
		print("DebugMenu: No active mission")
		return
	var idx := MissionManager.get_current_objective_index(active_id)
	if idx >= 0:
		MissionManager.complete_objective(active_id, idx)
		print("DebugMenu: Completed objective %d" % idx)
	else:
		print("DebugMenu: All objectives already complete")


# --- Scene Actions ---

func _on_goto_overworld() -> void:
	var sm = get_node_or_null("/root/Main/SceneManager")
	if sm:
		sm.change_scene("res://scenes/OverworldScene.tscn")

func _on_goto_playground() -> void:
	var sm = get_node_or_null("/root/Main/SceneManager")
	if sm:
		sm.change_scene("res://scenes/TestPlayground.tscn")

func _on_enter_crab_cave() -> void:
	DungeonManager.start_dungeon("crab_cave")

func _on_enter_tunnel() -> void:
	DungeonManager.start_dungeon("abandoned_tunnel")

func _on_start_delivery() -> void:
	var sm = get_node_or_null("/root/Main/SceneManager")
	if sm:
		sm.change_scene("res://scenes/Minigame_Delivery.tscn")


# --- Utility ---

func _get_scene_parent() -> Node:
	var sm = get_node_or_null("/root/Main/SceneManager")
	if sm and sm.has_method("get_current_scene") and sm.get_current_scene():
		return sm.get_current_scene()
	return get_tree().current_scene
