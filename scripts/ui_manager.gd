extends CanvasLayer
## UIManager — Manages all UI elements: HUD, panels, popups, notifications, pause, debug menu.
## Child of Main.tscn (not an autoload).
## Toggle screens: I = Inventory, K = Skill Tree, ESC = Pause, F3 = Debug Menu.

const HUD_SCENE := "res://scenes/ui/HUD.tscn"
const SKILL_TREE_SCENE := "res://scenes/ui/SkillTreePanel.tscn"
const INVENTORY_SCENE := "res://scenes/ui/InventoryPanel.tscn"
const PAUSE_MENU_SCENE := "res://scenes/ui/PauseMenu.tscn"
const DEBUG_MENU_SCENE := "res://scenes/ui/DebugMenu.tscn"
const MAIN_MENU_SCENE := "res://scenes/ui/MainMenu.tscn"
const GAME_OVER_SCENE := "res://scenes/ui/GameOverScreen.tscn"

signal hud_toggled(visible_state: bool)
signal screen_opened(screen_name: String)
signal screen_closed(screen_name: String)

var _hud: Control
var _skill_tree_panel: PanelContainer
var _inventory_panel: PanelContainer
var _pause_menu: PanelContainer
var _debug_menu: PanelContainer
var _main_menu: PanelContainer
var _game_over_screen: PanelContainer
var _notification_container: VBoxContainer
var _mission_tracker: VBoxContainer
var _time_display: Label
var _is_paused: bool = false
var _in_main_menu: bool = false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS  # UI processes even when paused

	_setup_hud()
	_setup_notification_area()
	_setup_mission_tracker()
	_setup_time_display()
	_connect_signals()
	print("UIManager: Ready.")


func _setup_hud() -> void:
	var packed := load(HUD_SCENE) as PackedScene
	if packed:
		_hud = packed.instantiate()
		add_child(_hud)


func _setup_notification_area() -> void:
	# Notification toasts stack in top-center
	_notification_container = VBoxContainer.new()
	_notification_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_notification_container.position = Vector2(490, 10)
	_notification_container.custom_minimum_size = Vector2(300, 0)
	_notification_container.add_theme_constant_override("separation", 4)
	_notification_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_notification_container)


func _setup_mission_tracker() -> void:
	# Mission tracker: top-right corner
	_mission_tracker = VBoxContainer.new()
	_mission_tracker.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_mission_tracker.position = Vector2(-280, 10)
	_mission_tracker.custom_minimum_size = Vector2(260, 0)
	_mission_tracker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_mission_tracker)


func _setup_time_display() -> void:
	# Time display: top-center-right
	_time_display = Label.new()
	_time_display.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_time_display.position = Vector2(420, 50)
	_time_display.custom_minimum_size = Vector2(200, 0)
	_time_display.add_theme_font_size_override("font_size", 12)
	_time_display.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	_time_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_time_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_time_display)


func _connect_signals() -> void:
	# Connect to CombatManager for damage popups
	CombatManager.damage_dealt.connect(_on_damage_dealt)

	# Connect to PlayerManager for level-up notifications
	PlayerManager.player_leveled_up.connect(_on_player_leveled_up)

	# Connect to InventoryManager for item pickup notifications
	InventoryManager.item_added.connect(_on_item_added)

	# Connect to SkillManager for skill unlock notifications
	SkillManager.skill_unlocked.connect(_on_skill_unlocked)

	# Connect to EconomyManager for rent notifications
	EconomyManager.rent_paid.connect(_on_rent_paid)
	EconomyManager.rent_failed.connect(_on_rent_failed)

	# Connect to DungeonManager for dungeon notifications
	DungeonManager.dungeon_started.connect(_on_dungeon_started)
	DungeonManager.dungeon_completed.connect(_on_dungeon_completed)
	DungeonManager.dungeon_failed.connect(_on_dungeon_failed)

	# Connect to MissionManager for mission notifications
	MissionManager.mission_started.connect(_on_mission_started)
	MissionManager.mission_completed.connect(_on_mission_completed)
	MissionManager.objective_completed.connect(_on_objective_completed)

	# Connect to SaveManager for save/load notifications
	SaveManager.game_saved.connect(func(): show_notification("Game saved!", 2.0))
	SaveManager.game_loaded.connect(func(): show_notification("Game loaded!", 2.0))


func _process(_delta: float) -> void:
	if not _in_main_menu:
		_update_mission_tracker()
		_update_time_display()


# --- Main Menu ---

func show_main_menu() -> void:
	_in_main_menu = true
	hide_hud()

	if _main_menu == null:
		var packed := load(MAIN_MENU_SCENE) as PackedScene
		if packed == null:
			return
		_main_menu = packed.instantiate()
		_main_menu.new_game_pressed.connect(_on_new_game)
		_main_menu.continue_pressed.connect(_on_continue)
		_main_menu.quit_pressed.connect(_on_quit)
		add_child(_main_menu)

	_main_menu.refresh()
	_main_menu.visible = true
	screen_opened.emit("main_menu")


func hide_main_menu() -> void:
	_in_main_menu = false
	if _main_menu:
		_main_menu.visible = false
	show_hud()
	screen_closed.emit("main_menu")


func _on_new_game() -> void:
	hide_main_menu()
	SaveManager.new_game()


func _on_continue() -> void:
	hide_main_menu()
	SaveManager.load_game()


func _on_quit() -> void:
	get_tree().quit()


# --- Game Over Screen ---

func show_game_over() -> void:
	if _game_over_screen == null:
		var packed := load(GAME_OVER_SCENE) as PackedScene
		if packed == null:
			return
		_game_over_screen = packed.instantiate()
		_game_over_screen.continue_pressed.connect(_on_death_continue)
		_game_over_screen.load_save_pressed.connect(_on_death_load)
		_game_over_screen.main_menu_pressed.connect(_on_death_menu)
		add_child(_game_over_screen)

	_game_over_screen.refresh()
	_game_over_screen.visible = true
	get_tree().paused = true
	screen_opened.emit("game_over")


func _hide_game_over() -> void:
	if _game_over_screen:
		_game_over_screen.visible = false
	get_tree().paused = false
	screen_closed.emit("game_over")


func _on_death_continue() -> void:
	## Continue: apply death penalty, return to overworld.
	_hide_game_over()
	SaveManager.apply_death_penalty()
	var scene_manager = get_node_or_null("/root/Main/SceneManager")
	if scene_manager:
		scene_manager.change_scene("res://scenes/OverworldScene.tscn")
	show_notification("Death penalty applied.", 3.0)


func _on_death_load() -> void:
	## Load most recent save (no penalty).
	_hide_game_over()
	SaveManager.load_game()


func _on_death_menu() -> void:
	## Return to main menu (no penalty).
	_hide_game_over()
	_go_to_main_menu()


# --- HUD ---

func show_hud() -> void:
	if _hud:
		_hud.visible = true
		hud_toggled.emit(true)


func hide_hud() -> void:
	if _hud:
		_hud.visible = false
		hud_toggled.emit(false)


# --- Inventory Panel ---

func toggle_inventory() -> void:
	if _is_paused or _in_main_menu:
		return

	# Close skill tree if open
	if _skill_tree_panel and _skill_tree_panel.visible:
		_close_skill_tree()

	if _inventory_panel and _inventory_panel.visible:
		_close_inventory()
	else:
		_open_inventory()


func _open_inventory() -> void:
	if _inventory_panel == null:
		var packed := load(INVENTORY_SCENE) as PackedScene
		if packed == null:
			return
		_inventory_panel = packed.instantiate()
		_inventory_panel.closed.connect(_close_inventory)
		add_child(_inventory_panel)
	_inventory_panel.visible = true
	screen_opened.emit("inventory")


func _close_inventory() -> void:
	if _inventory_panel:
		_inventory_panel.visible = false
		screen_closed.emit("inventory")


# --- Skill Tree Panel ---

func toggle_skill_tree() -> void:
	if _is_paused or _in_main_menu:
		return

	# Close inventory if open
	if _inventory_panel and _inventory_panel.visible:
		_close_inventory()

	if _skill_tree_panel and _skill_tree_panel.visible:
		_close_skill_tree()
	else:
		_open_skill_tree()


func _open_skill_tree() -> void:
	if _skill_tree_panel == null:
		var packed := load(SKILL_TREE_SCENE) as PackedScene
		if packed == null:
			return
		_skill_tree_panel = packed.instantiate()
		_skill_tree_panel.closed.connect(_close_skill_tree)
		add_child(_skill_tree_panel)
	_skill_tree_panel.visible = true
	_skill_tree_panel._refresh()
	screen_opened.emit("skill_tree")


func _close_skill_tree() -> void:
	if _skill_tree_panel:
		_skill_tree_panel.visible = false
		screen_closed.emit("skill_tree")


# --- Debug Menu ---

func toggle_debug_menu() -> void:
	if _debug_menu and _debug_menu.visible:
		_close_debug_menu()
	else:
		_open_debug_menu()


func _open_debug_menu() -> void:
	if _debug_menu == null:
		var packed := load(DEBUG_MENU_SCENE) as PackedScene
		if packed == null:
			return
		_debug_menu = packed.instantiate()
		_debug_menu.closed.connect(_close_debug_menu)
		add_child(_debug_menu)
	_debug_menu.visible = true
	screen_opened.emit("debug_menu")


func _close_debug_menu() -> void:
	if _debug_menu:
		_debug_menu.visible = false
		screen_closed.emit("debug_menu")


# --- Pause Menu ---

func _toggle_pause() -> void:
	if _in_main_menu:
		return

	# If a panel is open, close it instead of pausing
	if _debug_menu and _debug_menu.visible:
		_close_debug_menu()
		return
	if _skill_tree_panel and _skill_tree_panel.visible:
		_close_skill_tree()
		return
	if _inventory_panel and _inventory_panel.visible:
		_close_inventory()
		return

	if _is_paused:
		_unpause()
	else:
		_pause()


func _pause() -> void:
	_is_paused = true
	get_tree().paused = true
	GameState.is_paused = true

	if _pause_menu == null:
		var packed := load(PAUSE_MENU_SCENE) as PackedScene
		if packed == null:
			return
		_pause_menu = packed.instantiate()
		_pause_menu.resumed.connect(_unpause)
		_pause_menu.save_requested.connect(_on_pause_save)
		_pause_menu.load_requested.connect(_on_pause_load)
		_pause_menu.main_menu_requested.connect(_on_pause_main_menu)
		add_child(_pause_menu)

	_pause_menu.update_button_states()
	_pause_menu.visible = true
	screen_opened.emit("pause")


func _unpause() -> void:
	_is_paused = false
	get_tree().paused = false
	GameState.is_paused = false

	if _pause_menu:
		_pause_menu.visible = false
	screen_closed.emit("pause")


func _on_pause_save() -> void:
	var success := SaveManager.save_game()
	if success:
		_pause_menu.update_button_states()


func _on_pause_load() -> void:
	_unpause()
	SaveManager.load_game()


func _on_pause_main_menu() -> void:
	_unpause()
	_go_to_main_menu()


func _go_to_main_menu() -> void:
	show_main_menu()


# --- Mission Tracker ---

func _update_mission_tracker() -> void:
	if _mission_tracker == null:
		return

	# Clear old children
	for child in _mission_tracker.get_children():
		child.queue_free()

	var active_id := MissionManager.get_active_mission_id()
	if active_id == "":
		return

	var data: Dictionary = MissionManager.get_active_mission_data()
	if data.is_empty():
		return

	# Mission name
	var title := Label.new()
	title.text = data.get("display_name", active_id)
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mission_tracker.add_child(title)

	# Objectives
	var objectives: Array = data.get("objectives", [])
	var status: Array = MissionManager.get_objective_status(active_id)

	for i in range(objectives.size()):
		var obj: Dictionary = objectives[i]
		var done: bool = status[i] if i < status.size() else false

		var obj_label := Label.new()
		var desc := MissionManager._describe_objective(obj)
		if done:
			obj_label.text = "[x] %s" % desc
			obj_label.add_theme_color_override("font_color", Color(0.4, 0.7, 0.4))
		else:
			obj_label.text = "[ ] %s" % desc
			obj_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		obj_label.add_theme_font_size_override("font_size", 11)
		obj_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		obj_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_mission_tracker.add_child(obj_label)


# --- Time Display ---

func _update_time_display() -> void:
	if _time_display == null:
		return
	_time_display.text = TimeManager.get_time_string()

	# Color based on time of day
	if TimeManager.is_night():
		_time_display.add_theme_color_override("font_color", Color(0.4, 0.4, 0.7))
	else:
		_time_display.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))


# --- Notifications ---

func show_notification(text: String, duration: float = 2.0) -> void:
	var toast_script := load("res://scripts/ui/notification_toast.gd")
	var toast := PanelContainer.new()
	toast.set_script(toast_script)
	_notification_container.add_child(toast)
	toast.setup(text, duration)


# --- Damage Popups ---

func spawn_damage_popup(world_position: Vector2, amount: float, is_crit: bool = false, is_dodge: bool = false) -> void:
	var popup_script := load("res://scripts/ui/damage_popup.gd")
	var popup := Node2D.new()
	popup.set_script(popup_script)
	popup.setup(amount, is_crit, is_dodge)

	# Add to game world so it follows world coordinates
	var scene_parent := _get_scene_parent()
	if scene_parent:
		scene_parent.add_child(popup)
		popup.global_position = world_position


func _get_scene_parent() -> Node:
	var sm = get_node_or_null("/root/Main/SceneManager")
	if sm and sm.has_method("get_current_scene") and sm.get_current_scene():
		return sm.get_current_scene()
	return get_tree().current_scene


# --- Signal Handlers ---

func _on_damage_dealt(target: Node, amount: float, is_crit: bool, is_dodge: bool) -> void:
	if is_instance_valid(target):
		spawn_damage_popup(target.global_position + Vector2(0, -20), amount, is_crit, is_dodge)


func _on_player_leveled_up(_player_id: int, new_level: int) -> void:
	show_notification("Level Up! Now level %d" % new_level, 3.0)


func _on_item_added(_player_id: int, item_id: String) -> void:
	var item_data: Dictionary = DataManager.get_item(item_id)
	var item_name: String = item_data.get("display_name", item_id)
	show_notification("Picked up: %s" % item_name)


func _on_skill_unlocked(_player_id: int, skill_id: String) -> void:
	var skill_data: Dictionary = DataManager.get_skill(skill_id)
	var skill_name: String = skill_data.get("display_name", skill_id)
	show_notification("Skill unlocked: %s" % skill_name, 2.5)


func _on_rent_paid(_player_id: int, amount: int) -> void:
	show_notification("Rent paid: $%d" % amount, 3.0)


func _on_rent_failed(_player_id: int, amount: int) -> void:
	show_notification("Cannot afford rent! Need $%d" % amount, 4.0)


func _on_dungeon_started(dungeon_id: String) -> void:
	var dungeon_data: Dictionary = DataManager.get_dungeon(dungeon_id)
	var dungeon_name: String = dungeon_data.get("display_name", dungeon_id)
	show_notification("Entering: %s" % dungeon_name, 2.5)


func _on_dungeon_completed(dungeon_id: String) -> void:
	var dungeon_data: Dictionary = DataManager.get_dungeon(dungeon_id)
	var dungeon_name: String = dungeon_data.get("display_name", dungeon_id)
	show_notification("Dungeon Complete: %s" % dungeon_name, 3.0)


func _on_dungeon_failed(dungeon_id: String) -> void:
	var dungeon_data: Dictionary = DataManager.get_dungeon(dungeon_id)
	var dungeon_name: String = dungeon_data.get("display_name", dungeon_id)
	show_notification("Dungeon Failed: %s" % dungeon_name, 3.0)


func _on_mission_started(mission_id: String) -> void:
	var data: Dictionary = DataManager.get_mission(mission_id)
	show_notification("Mission: %s" % data.get("display_name", mission_id), 3.0)


func _on_mission_completed(mission_id: String) -> void:
	var data: Dictionary = DataManager.get_mission(mission_id)
	show_notification("Mission Complete: %s" % data.get("display_name", mission_id), 3.0)


func _on_objective_completed(mission_id: String, _objective_index: int) -> void:
	show_notification("Objective completed!", 1.5)
