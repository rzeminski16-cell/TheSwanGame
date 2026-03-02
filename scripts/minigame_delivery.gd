extends Node2D
## Minigame_Delivery — Bird's-eye driving delivery mini-game.
## Player drives to delivery points on a simple map to earn money.
## No failure states in demo. Future-ready for police/rival events.

signal delivery_completed(reward: int)

const MAP_SIZE := Vector2(1280, 720)
const PLAYER_SPEED := 250.0
const DELIVERY_RADIUS := 40.0

var _player_sprite: ColorRect
var _player_pos: Vector2
var _delivery_points: Array = []  # Array of Vector2 positions
var _current_target: int = 0
var _total_points: int = 3
var _completed: bool = false
var _reward_per_point: int = 0
var _target_markers: Array = []  # Node references
var _info_label: Label
var _delivery_job_id: String = "delivery_basic_1"


func _ready() -> void:
	# Load delivery job data
	var jobs: Array = DataManager.get_delivery_jobs()
	if jobs.size() > 0:
		var job: Dictionary = jobs[0]
		_delivery_job_id = job.get("id", "delivery_basic_1")
		_total_points = int(job.get("delivery_points", 3))

	_reward_per_point = EconomyManager.get_delivery_reward(1)

	_build_map()
	_generate_delivery_points()
	_spawn_player()
	_build_ui()

	print("Minigame_Delivery: Ready — deliver to %d points. WASD to drive." % _total_points)


func _build_map() -> void:
	# Street background
	var bg := ColorRect.new()
	bg.color = Color(0.25, 0.25, 0.28)
	bg.size = MAP_SIZE
	bg.z_index = -10
	add_child(bg)

	# Road grid
	for i in range(4):
		var h_road := ColorRect.new()
		h_road.color = Color(0.35, 0.35, 0.38)
		h_road.position = Vector2(0, 120 + i * 150)
		h_road.size = Vector2(MAP_SIZE.x, 40)
		h_road.z_index = -5
		add_child(h_road)

	for i in range(5):
		var v_road := ColorRect.new()
		v_road.color = Color(0.35, 0.35, 0.38)
		v_road.position = Vector2(100 + i * 250, 0)
		v_road.size = Vector2(40, MAP_SIZE.y)
		v_road.z_index = -5
		add_child(v_road)


func _generate_delivery_points() -> void:
	_delivery_points.clear()
	for marker in _target_markers:
		if is_instance_valid(marker):
			marker.queue_free()
	_target_markers.clear()

	for i in range(_total_points):
		var pos := Vector2(
			randf_range(100, MAP_SIZE.x - 100),
			randf_range(100, MAP_SIZE.y - 100)
		)
		_delivery_points.append(pos)

		# Marker
		var marker := Node2D.new()
		marker.position = pos

		var marker_vis := ColorRect.new()
		marker_vis.color = Color(1.0, 0.3, 0.3) if i == 0 else Color(0.5, 0.5, 0.5)
		marker_vis.size = Vector2(30, 30)
		marker_vis.position = Vector2(-15, -15)
		marker.add_child(marker_vis)
		marker.set_meta("vis", marker_vis)

		var marker_label := Label.new()
		marker_label.text = str(i + 1)
		marker_label.add_theme_font_size_override("font_size", 14)
		marker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		marker_label.position = Vector2(-10, -22)
		marker_label.size = Vector2(20, 20)
		marker.add_child(marker_label)

		add_child(marker)
		_target_markers.append(marker)


func _spawn_player() -> void:
	_player_pos = Vector2(640, 600)

	_player_sprite = ColorRect.new()
	_player_sprite.color = Color(0.2, 0.7, 1.0)
	_player_sprite.size = Vector2(20, 20)
	_player_sprite.position = _player_pos - Vector2(10, 10)
	_player_sprite.z_index = 10
	add_child(_player_sprite)


func _build_ui() -> void:
	_info_label = Label.new()
	_info_label.add_theme_font_size_override("font_size", 16)
	_info_label.position = Vector2(10, 10)
	_info_label.size = Vector2(400, 30)
	_info_label.z_index = 50
	add_child(_info_label)
	_update_info()


func _process(delta: float) -> void:
	if _completed:
		return

	# Movement
	var input := Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		input.y -= 1
	if Input.is_action_pressed("move_down"):
		input.y += 1
	if Input.is_action_pressed("move_left"):
		input.x -= 1
	if Input.is_action_pressed("move_right"):
		input.x += 1

	if input != Vector2.ZERO:
		input = input.normalized()
		_player_pos += input * PLAYER_SPEED * delta
		_player_pos = _player_pos.clamp(Vector2(10, 10), MAP_SIZE - Vector2(10, 10))
		_player_sprite.position = _player_pos - Vector2(10, 10)

	# Check delivery
	if _current_target < _delivery_points.size():
		var target_pos: Vector2 = _delivery_points[_current_target]
		if _player_pos.distance_to(target_pos) < DELIVERY_RADIUS:
			_complete_delivery_point()


func _complete_delivery_point() -> void:
	# Mark current as done (green)
	var marker: Node2D = _target_markers[_current_target]
	var vis = marker.get_meta("vis")
	if vis:
		vis.color = Color(0.2, 0.8, 0.2)

	EconomyManager.add_money(1, _reward_per_point)
	print("Minigame_Delivery: Delivered point %d — earned %d" % [_current_target + 1, _reward_per_point])

	_current_target += 1

	if _current_target >= _delivery_points.size():
		_finish_delivery()
	else:
		# Highlight next target
		var next_vis = _target_markers[_current_target].get_meta("vis")
		if next_vis:
			next_vis.color = Color(1.0, 0.3, 0.3)

	_update_info()


func _finish_delivery() -> void:
	_completed = true
	_info_label.text = "All deliveries complete! Returning..."

	MissionManager.notify_deliver_item(_delivery_job_id)

	var ui = get_node_or_null("/root/Main/UIManager")
	if ui and ui.has_method("show_notification"):
		ui.show_notification("All deliveries complete!", 2.5)

	# Return to overworld after delay
	await get_tree().create_timer(2.0).timeout
	_return_to_overworld()


func _update_info() -> void:
	if _completed:
		return
	_info_label.text = "Delivery %d/%d — Reward: $%d each" % [_current_target + 1, _total_points, _reward_per_point]


func _input(event: InputEvent) -> void:
	# Allow ESC to abort and return
	if event.is_action_pressed("pause"):
		_return_to_overworld()


func _return_to_overworld() -> void:
	var sm = get_node_or_null("/root/Main/SceneManager")
	if sm:
		sm.change_scene("res://scenes/OverworldScene.tscn")
