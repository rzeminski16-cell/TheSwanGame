extends Node2D
## OverworldScene — Bay Campus overworld map.
## Contains NPC spawn points, location triggers, and dungeon entrances.
## Time system runs here; pauses when entering dungeons.

var _player_node: Node = null
var _npc_nodes: Dictionary = {}  # npc_id → Node2D
var _location_areas: Dictionary = {}  # location_id → Area2D

const MAP_WIDTH := 2560.0
const MAP_HEIGHT := 1440.0

# NPC definitions: id, display name, position
const NPC_DEFS := [
	{"id": "hannan", "name": "Hannan", "pos": Vector2(400, 350), "color": Color(0.2, 0.8, 0.4)},
	{"id": "lewis", "name": "Lewis", "pos": Vector2(900, 500), "color": Color(0.6, 0.4, 0.9)},
	{"id": "luka", "name": "Luka", "pos": Vector2(1500, 400), "color": Color(0.9, 0.6, 0.2)},
	{"id": "jack", "name": "Jack", "pos": Vector2(1800, 700), "color": Color(0.2, 0.6, 0.9)},
]

# Location definitions: id, display name, position, size
const LOCATION_DEFS := [
	{"id": "player_house", "name": "Your House", "pos": Vector2(200, 200), "size": Vector2(120, 100), "color": Color(0.3, 0.5, 0.3)},
	{"id": "rent_box", "name": "Rent Box", "pos": Vector2(350, 200), "size": Vector2(60, 60), "color": Color(0.8, 0.6, 0.2)},
	{"id": "crab_cave_entrance", "name": "Crab Cave", "pos": Vector2(2000, 300), "size": Vector2(100, 80), "color": Color(0.5, 0.2, 0.2)},
	{"id": "tunnel_entrance", "name": "Abandoned Tunnel", "pos": Vector2(2200, 800), "size": Vector2(100, 80), "color": Color(0.3, 0.2, 0.4)},
	{"id": "delivery_board", "name": "Delivery Board", "pos": Vector2(700, 250), "size": Vector2(80, 60), "color": Color(0.2, 0.4, 0.7)},
]


func _ready() -> void:
	_build_map()
	_spawn_npcs()
	_spawn_locations()
	_spawn_player()

	# Start time system in overworld
	TimeManager.start_time()

	# Connect time signals for rent
	TimeManager.week_ended.connect(_on_week_ended)

	# Start tutorial mission if no mission active
	if MissionManager.get_active_mission_id() == "":
		if not MissionManager.is_mission_completed("mission_tutorial"):
			MissionManager.start_mission("mission_tutorial")

	print("OverworldScene: Ready. Explore Bay Campus!")
	print("  E: Interact | WASD: Move")


func _build_map() -> void:
	# Ground
	var ground := ColorRect.new()
	ground.color = Color(0.15, 0.2, 0.12)
	ground.position = Vector2.ZERO
	ground.size = Vector2(MAP_WIDTH, MAP_HEIGHT)
	ground.z_index = -10
	add_child(ground)

	# Paths (decorative)
	_draw_path(Vector2(200, 260), Vector2(700, 260))
	_draw_path(Vector2(700, 260), Vector2(1500, 400))
	_draw_path(Vector2(1500, 400), Vector2(2000, 340))
	_draw_path(Vector2(700, 260), Vector2(900, 500))

	# Map boundary walls
	_create_boundary_wall(Vector2(MAP_WIDTH / 2, -10), Vector2(MAP_WIDTH, 20))  # Top
	_create_boundary_wall(Vector2(MAP_WIDTH / 2, MAP_HEIGHT + 10), Vector2(MAP_WIDTH, 20))  # Bottom
	_create_boundary_wall(Vector2(-10, MAP_HEIGHT / 2), Vector2(20, MAP_HEIGHT))  # Left
	_create_boundary_wall(Vector2(MAP_WIDTH + 10, MAP_HEIGHT / 2), Vector2(20, MAP_HEIGHT))  # Right


func _draw_path(from: Vector2, to: Vector2) -> void:
	var path_rect := ColorRect.new()
	path_rect.color = Color(0.25, 0.22, 0.18)
	var dir := (to - from)
	var length := dir.length()
	path_rect.size = Vector2(length, 20)
	path_rect.position = from - Vector2(0, 10)
	path_rect.rotation = dir.angle()
	path_rect.z_index = -5
	add_child(path_rect)


func _create_boundary_wall(pos: Vector2, wall_size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = wall_size
	shape.shape = rect
	body.add_child(shape)

	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)


func _spawn_npcs() -> void:
	for npc_def in NPC_DEFS:
		var npc := _create_npc(npc_def)
		_npc_nodes[npc_def["id"]] = npc
		add_child(npc)


func _create_npc(npc_def: Dictionary) -> Node2D:
	var npc := CharacterBody2D.new()
	npc.name = "NPC_%s" % npc_def["id"]
	npc.position = npc_def["pos"]
	npc.collision_layer = 4  # NPC layer
	npc.collision_mask = 0

	# Visual: colored circle
	var sprite := ColorRect.new()
	sprite.color = npc_def["color"]
	sprite.size = Vector2(24, 32)
	sprite.position = Vector2(-12, -16)
	npc.add_child(sprite)

	# Collision
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(24, 32)
	col.shape = shape
	npc.add_child(col)

	# Interact area (larger than body)
	var interact_area := Area2D.new()
	interact_area.name = "InteractArea"
	interact_area.collision_layer = 0
	interact_area.collision_mask = 2  # Player layer
	var area_shape := CollisionShape2D.new()
	var area_rect := CircleShape2D.new()
	area_rect.radius = 50.0
	area_shape.shape = area_rect
	interact_area.add_child(area_shape)
	npc.add_child(interact_area)

	# Name label
	var label := Label.new()
	label.text = npc_def["name"]
	label.add_theme_font_size_override("font_size", 11)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-30, -30)
	label.size = Vector2(60, 20)
	npc.add_child(label)

	# Store npc_id on node
	npc.set_meta("npc_id", npc_def["id"])

	return npc


func _spawn_locations() -> void:
	for loc_def in LOCATION_DEFS:
		var loc := _create_location(loc_def)
		_location_areas[loc_def["id"]] = loc
		add_child(loc)


func _create_location(loc_def: Dictionary) -> Area2D:
	var area := Area2D.new()
	area.name = "Location_%s" % loc_def["id"]
	area.position = loc_def["pos"]
	area.collision_layer = 0
	area.collision_mask = 2  # Player layer

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = loc_def["size"]
	col.shape = shape
	area.add_child(col)

	# Visual: colored rectangle
	var vis := ColorRect.new()
	vis.color = loc_def["color"]
	vis.size = loc_def["size"]
	vis.position = -loc_def["size"] / 2.0
	vis.modulate.a = 0.5
	area.add_child(vis)

	# Label
	var label := Label.new()
	label.text = loc_def["name"]
	label.add_theme_font_size_override("font_size", 10)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-loc_def["size"].x / 2.0, -loc_def["size"].y / 2.0 - 16)
	label.size = Vector2(loc_def["size"].x, 16)
	area.add_child(label)

	# Connect body entered
	area.body_entered.connect(_on_location_entered.bind(loc_def["id"]))
	area.set_meta("location_id", loc_def["id"])

	return area


func _spawn_player() -> void:
	# Spawn all active players
	var player_ids := MultiplayerManager.get_all_player_ids()
	var spawn_offsets := [Vector2(0, 0), Vector2(40, 0), Vector2(0, 40), Vector2(40, 40)]

	for i in range(player_ids.size()):
		var pid: int = player_ids[i]
		var node := PlayerManager.spawn_player(pid, self)
		if node == null:
			continue

		var offset: Vector2 = spawn_offsets[i] if i < spawn_offsets.size() else Vector2(i * 30, 0)
		node.position = Vector2(260, 250) + offset

		# Setup multiplayer authority
		if node.has_method("setup_multiplayer"):
			var peer_id := GameState.get_peer_id_for_player(pid)
			if peer_id <= 0:
				peer_id = 1  # Single player default
			node.setup_multiplayer(peer_id)

		# Camera follows the local player only
		var is_local := not GameState.is_multiplayer or (pid == MultiplayerManager.get_local_player_id())
		if is_local:
			_player_node = node
			var camera := Camera2D.new()
			camera.enabled = true
			camera.limit_left = 0
			camera.limit_top = 0
			camera.limit_right = int(MAP_WIDTH)
			camera.limit_bottom = int(MAP_HEIGHT)
			camera.position_smoothing_enabled = true
			camera.position_smoothing_speed = 8.0
			node.add_child(camera)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()


func _try_interact() -> void:
	if _player_node == null:
		return

	# Check if near an NPC
	var player_pos: Vector2 = _player_node.global_position
	for npc_id in _npc_nodes:
		var npc: Node2D = _npc_nodes[npc_id]
		if player_pos.distance_to(npc.global_position) < 60.0:
			_interact_with_npc(npc_id)
			return

	# Check dungeon entrances
	for loc_id in _location_areas:
		var area: Area2D = _location_areas[loc_id]
		if player_pos.distance_to(area.global_position) < 80.0:
			_interact_with_location(loc_id)
			return


func _interact_with_npc(npc_id: String) -> void:
	print("OverworldScene: Talking to %s" % npc_id)
	MissionManager.notify_talk_to_npc(npc_id)

	var ui = get_node_or_null("/root/Main/UIManager")
	if ui and ui.has_method("show_notification"):
		var npc_name := npc_id.capitalize()
		ui.show_notification("Talked to %s" % npc_name, 1.5)


func _interact_with_location(location_id: String) -> void:
	match location_id:
		"crab_cave_entrance":
			print("OverworldScene: Entering Crab Cave")
			MissionManager.notify_enter_dungeon("crab_cave")
			TimeManager.pause_time()
			DungeonManager.start_dungeon("crab_cave")
		"tunnel_entrance":
			print("OverworldScene: Entering Abandoned Tunnel")
			MissionManager.notify_enter_dungeon("abandoned_tunnel")
			TimeManager.pause_time()
			DungeonManager.start_dungeon("abandoned_tunnel")
		"delivery_board":
			print("OverworldScene: Opening delivery board")
			_start_delivery()
		"rent_box":
			print("OverworldScene: Paying rent")
			MissionManager.notify_reach_location("rent_box")
			var success := EconomyManager.pay_rent(1)
			var ui = get_node_or_null("/root/Main/UIManager")
			if ui and ui.has_method("show_notification"):
				if success:
					ui.show_notification("Rent paid!", 2.0)
				else:
					ui.show_notification("Not enough money for rent!", 2.0)
		"player_house":
			MissionManager.notify_reach_location("player_house")
			MissionManager.notify_return_home()
			var ui = get_node_or_null("/root/Main/UIManager")
			if ui and ui.has_method("show_notification"):
				ui.show_notification("Home sweet home", 1.5)


func _on_location_entered(_body: Node, location_id: String) -> void:
	MissionManager.notify_reach_location(location_id)


func _start_delivery() -> void:
	TimeManager.pause_time()
	var sm = get_node_or_null("/root/Main/SceneManager")
	if sm:
		sm.change_scene("res://scenes/Minigame_Delivery.tscn")


func _on_week_ended(week_number: int) -> void:
	var ui = get_node_or_null("/root/Main/UIManager")
	if ui and ui.has_method("show_notification"):
		ui.show_notification("Week %d over — rent is due!" % week_number, 4.0)


func _exit_tree() -> void:
	TimeManager.pause_time()
