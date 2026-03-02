extends CanvasLayer
## UIManager — Manages all UI elements: HUD, panels, popups, notifications, pause.
## Child of Main.tscn (not an autoload).
## Toggle screens: I = Inventory, K = Skill Tree, ESC = Pause.

const HUD_SCENE := "res://scenes/ui/HUD.tscn"
const SKILL_TREE_SCENE := "res://scenes/ui/SkillTreePanel.tscn"
const INVENTORY_SCENE := "res://scenes/ui/InventoryPanel.tscn"
const PAUSE_MENU_SCENE := "res://scenes/ui/PauseMenu.tscn"

signal hud_toggled(visible_state: bool)
signal screen_opened(screen_name: String)
signal screen_closed(screen_name: String)

var _hud: Control
var _skill_tree_panel: PanelContainer
var _inventory_panel: PanelContainer
var _pause_menu: PanelContainer
var _notification_container: VBoxContainer
var _is_paused: bool = false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS  # UI processes even when paused

	_setup_hud()
	_setup_notification_area()
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


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return

	if event.is_action_pressed("toggle_inventory"):
		toggle_inventory()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_skill_tree"):
		toggle_skill_tree()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()


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
	if _is_paused:
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
	if _is_paused:
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


# --- Pause Menu ---

func _toggle_pause() -> void:
	# If a panel is open, close it instead of pausing
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
		add_child(_pause_menu)
	_pause_menu.visible = true
	screen_opened.emit("pause")


func _unpause() -> void:
	_is_paused = false
	get_tree().paused = false
	GameState.is_paused = false

	if _pause_menu:
		_pause_menu.visible = false
	screen_closed.emit("pause")


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
	var name: String = item_data.get("display_name", item_id)
	show_notification("Picked up: %s" % name)


func _on_skill_unlocked(_player_id: int, skill_id: String) -> void:
	var skill_data: Dictionary = DataManager.get_skill(skill_id)
	var skill_name: String = skill_data.get("display_name", skill_id)
	show_notification("Skill unlocked: %s" % skill_name, 2.5)


func _on_rent_paid(_player_id: int, amount: int) -> void:
	show_notification("Rent paid: $%d" % amount, 3.0)


func _on_rent_failed(_player_id: int, amount: int) -> void:
	show_notification("Cannot afford rent! Need $%d" % amount, 4.0)
