extends Node2D
## DungeonScene — Combat arena for dungeon rooms.
## Spawns player, builds walls, connects to DungeonManager for room progression.
## Player death triggers dungeon failure via DungeonManager.

var _player_node: Node = null
var _room_label: Label
var _dungeon_name_label: Label

const ARENA_LEFT := 80.0
const ARENA_RIGHT := 1200.0
const ARENA_TOP := 60.0
const ARENA_BOTTOM := 660.0
const WALL_THICKNESS := 20.0


func _ready() -> void:
	_build_arena_walls()
	_build_dungeon_ui()
	_spawn_player()
	_connect_signals()

	# Start first room after a short delay (let scene settle)
	await get_tree().create_timer(0.5).timeout
	DungeonManager.start_next_room()


func _build_arena_walls() -> void:
	# Floor color
	var floor_rect := ColorRect.new()
	floor_rect.color = Color(0.08, 0.08, 0.1)
	floor_rect.position = Vector2(ARENA_LEFT, ARENA_TOP)
	floor_rect.size = Vector2(ARENA_RIGHT - ARENA_LEFT, ARENA_BOTTOM - ARENA_TOP)
	floor_rect.z_index = -10
	add_child(floor_rect)

	# Top wall
	_create_wall(Vector2(ARENA_LEFT, ARENA_TOP - WALL_THICKNESS),
		Vector2(ARENA_RIGHT - ARENA_LEFT, WALL_THICKNESS))
	# Bottom wall
	_create_wall(Vector2(ARENA_LEFT, ARENA_BOTTOM),
		Vector2(ARENA_RIGHT - ARENA_LEFT, WALL_THICKNESS))
	# Left wall
	_create_wall(Vector2(ARENA_LEFT - WALL_THICKNESS, ARENA_TOP - WALL_THICKNESS),
		Vector2(WALL_THICKNESS, ARENA_BOTTOM - ARENA_TOP + WALL_THICKNESS * 2))
	# Right wall
	_create_wall(Vector2(ARENA_RIGHT, ARENA_TOP - WALL_THICKNESS),
		Vector2(WALL_THICKNESS, ARENA_BOTTOM - ARENA_TOP + WALL_THICKNESS * 2))


func _create_wall(pos: Vector2, wall_size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = wall_size
	shape.shape = rect
	shape.position = wall_size / 2.0
	body.add_child(shape)

	# Collision layer 1 (environment)
	body.collision_layer = 1
	body.collision_mask = 0

	# Visual
	var vis := ColorRect.new()
	vis.color = Color(0.25, 0.2, 0.15)
	vis.size = wall_size
	body.add_child(vis)

	add_child(body)


func _build_dungeon_ui() -> void:
	# Dungeon name at top center
	_dungeon_name_label = Label.new()
	_dungeon_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dungeon_name_label.add_theme_font_size_override("font_size", 18)
	_dungeon_name_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	_dungeon_name_label.position = Vector2(440, 10)
	_dungeon_name_label.size = Vector2(400, 30)
	_dungeon_name_label.z_index = 50

	var dungeon_data: Dictionary = DungeonManager.get_active_dungeon_data()
	_dungeon_name_label.text = dungeon_data.get("display_name", "Dungeon")
	add_child(_dungeon_name_label)

	# Room counter below dungeon name
	_room_label = Label.new()
	_room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_room_label.add_theme_font_size_override("font_size", 14)
	_room_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_room_label.position = Vector2(440, 32)
	_room_label.size = Vector2(400, 25)
	_room_label.z_index = 50
	_room_label.text = "Preparing..."
	add_child(_room_label)


func _spawn_player() -> void:
	_player_node = PlayerManager.spawn_player(1, self)
	if _player_node:
		_player_node.position = Vector2(640, 500)  # Bottom center of arena

		# Heal player to full on dungeon entry
		var hc = _player_node.get_node_or_null("HealthComponent")
		if hc and hc.has_method("heal_full"):
			hc.heal_full()


func _connect_signals() -> void:
	DungeonManager.room_started.connect(_on_room_started)
	DungeonManager.room_cleared.connect(_on_room_cleared)
	DungeonManager.dungeon_completed.connect(_on_dungeon_completed)

	# Connect player death
	if _player_node:
		var hc = _player_node.get_node_or_null("HealthComponent")
		if hc:
			hc.died.connect(_on_player_died)


func _on_room_started(room_index: int, total_rooms: int) -> void:
	var room_data: Dictionary = DungeonManager.get_active_dungeon_data().get("rooms", [])[room_index]
	var room_type: String = room_data.get("room_type", "combat")

	if room_type == "boss":
		_room_label.text = "Room %d/%d — BOSS" % [room_index + 1, total_rooms]
		_room_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		_room_label.text = "Room %d/%d" % [room_index + 1, total_rooms]
		_room_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

	# Notify UIManager
	var ui = get_node_or_null("/root/Main/UIManager")
	if ui and ui.has_method("show_notification"):
		if room_type == "boss":
			ui.show_notification("BOSS FIGHT!", 2.0)
		else:
			ui.show_notification("Room %d/%d" % [room_index + 1, total_rooms], 1.5)


func _on_room_cleared(room_index: int) -> void:
	var total := DungeonManager.get_total_rooms()
	if room_index + 1 < total:
		_room_label.text = "Room Cleared! Next room..."
		_room_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	else:
		_room_label.text = "All rooms cleared!"
		_room_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))

	var ui = get_node_or_null("/root/Main/UIManager")
	if ui and ui.has_method("show_notification"):
		if room_index + 1 < total:
			ui.show_notification("Room Cleared!", 1.5)
		else:
			ui.show_notification("Dungeon Complete!", 3.0)


func _on_dungeon_completed(_dungeon_id: String) -> void:
	# Scene will be changed by DungeonManager
	pass


func _on_player_died() -> void:
	# Brief delay then fail
	var ui = get_node_or_null("/root/Main/UIManager")
	if ui and ui.has_method("show_notification"):
		ui.show_notification("You died! Penalty applied...", 3.0)

	await get_tree().create_timer(1.5).timeout
	DungeonManager.fail_dungeon()
