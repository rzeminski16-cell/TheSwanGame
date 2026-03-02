extends Node
## AIComponent — Enemy AI state machine.
## Supports melee, ranged, and boss behavior types.
## States: IDLE, CHASE, ATTACK, RETREAT, DEAD

enum State { IDLE, CHASE, ATTACK, RETREAT, DEAD }

var _state: State = State.IDLE
var _enemy: CharacterBody2D = null
var _target: Node2D = null
var _enemy_type: String = "melee"

# Timers
var _attack_cooldown: float = 0.0
var _attack_timer: float = 0.0
var _detection_range: float = 300.0
var _attack_range: float = 0.0
var _retreat_range: float = 0.0

# Boss phase tracking
var _boss_phase: int = 1
var _boss_phase2_threshold: float = 0.50

# Ranged projectile
const PROJECTILE_SCENE_PATH := "res://scenes/entities/Projectile.tscn"


func setup(enemy: CharacterBody2D) -> void:
	_enemy = enemy
	_enemy_type = enemy.get_enemy_type()

	var attack_speed: float = enemy.get_stat("attack_speed")
	_attack_cooldown = 1.0 / maxf(0.1, attack_speed)
	_attack_timer = 0.0

	match _enemy_type:
		"melee":
			_attack_range = 30.0
			_detection_range = 250.0
		"ranged":
			_attack_range = 200.0
			_retreat_range = 80.0
			_detection_range = 350.0
		"boss":
			_attack_range = 40.0
			_detection_range = 500.0


func _physics_process(delta: float) -> void:
	if _enemy == null or _state == State.DEAD:
		return

	# Check if enemy died
	if _enemy.health_component and _enemy.health_component.is_dead:
		_state = State.DEAD
		return

	_attack_timer = maxf(0.0, _attack_timer - delta)

	# Find closest player target
	_target = _find_closest_player()

	match _enemy_type:
		"melee":
			_process_melee(delta)
		"ranged":
			_process_ranged(delta)
		"boss":
			_process_boss(delta)


func _process_melee(_delta: float) -> void:
	if _target == null:
		_state = State.IDLE
		return

	var dist := _enemy.global_position.distance_to(_target.global_position)

	if dist > _detection_range:
		_state = State.IDLE
		_enemy.velocity = Vector2.ZERO
	elif dist <= _attack_range:
		_state = State.ATTACK
		_enemy.velocity = Vector2.ZERO
		_try_attack()
	else:
		_state = State.CHASE
		_move_toward_target()

	_enemy.move_and_slide()


func _process_ranged(_delta: float) -> void:
	if _target == null:
		_state = State.IDLE
		return

	var dist := _enemy.global_position.distance_to(_target.global_position)

	if dist > _detection_range:
		_state = State.IDLE
		_enemy.velocity = Vector2.ZERO
	elif dist < _retreat_range:
		# Too close, back away
		_state = State.RETREAT
		_move_away_from_target()
	elif dist <= _attack_range:
		_state = State.ATTACK
		_enemy.velocity = Vector2.ZERO
		_try_ranged_attack()
	else:
		_state = State.CHASE
		_move_toward_target()

	_enemy.move_and_slide()


func _process_boss(delta: float) -> void:
	if _target == null:
		_state = State.IDLE
		return

	# Check phase transition
	if _boss_phase == 1 and _enemy.health_component:
		if _enemy.health_component.get_health_percent() <= _boss_phase2_threshold:
			_boss_phase = 2
			_attack_range = 200.0  # Switch to ranged in phase 2
			_attack_cooldown *= 0.7  # Attack faster
			print("AIComponent: Boss entering phase 2!")

	var dist := _enemy.global_position.distance_to(_target.global_position)

	if dist <= _attack_range:
		_state = State.ATTACK
		_enemy.velocity = Vector2.ZERO
		if _boss_phase == 1:
			_try_attack()  # Melee slam
		else:
			_try_ranged_attack()  # Projectile spray
	else:
		_state = State.CHASE
		_move_toward_target()

	_enemy.move_and_slide()


func _move_toward_target() -> void:
	if _target == null or _enemy == null:
		return
	var dir := (_target.global_position - _enemy.global_position).normalized()
	var speed: float = _enemy.get_stat("move_speed")
	_enemy.velocity = dir * speed


func _move_away_from_target() -> void:
	if _target == null or _enemy == null:
		return
	var dir := (_enemy.global_position - _target.global_position).normalized()
	var speed: float = _enemy.get_stat("move_speed")
	_enemy.velocity = dir * speed


func _try_attack() -> void:
	if _attack_timer > 0.0 or _target == null:
		return
	_attack_timer = _attack_cooldown

	# Melee attack — use CombatManager for damage
	var damage: float = _enemy.get_stat("damage")
	CombatManager.apply_damage(_enemy, _target, damage)


func _try_ranged_attack() -> void:
	if _attack_timer > 0.0 or _target == null:
		return
	_attack_timer = _attack_cooldown

	_spawn_projectile()


func _spawn_projectile() -> void:
	var packed := load(PROJECTILE_SCENE_PATH) as PackedScene
	if packed == null:
		return

	var proj := packed.instantiate()
	var dir := (_target.global_position - _enemy.global_position).normalized()
	var damage: float = _enemy.get_stat("damage")

	if proj.has_method("setup"):
		proj.setup(dir, damage, _enemy, "enemy")

	_enemy.get_parent().add_child(proj)
	proj.global_position = _enemy.global_position


func _find_closest_player() -> Node2D:
	var players := _enemy.get_tree().get_nodes_in_group("players")
	if players.is_empty():
		# Fallback: find any Player node
		var player = PlayerManager.get_player_node(1)
		if player and is_instance_valid(player):
			return player
		return null

	var closest: Node2D = null
	var closest_dist: float = INF
	for p in players:
		if not is_instance_valid(p):
			continue
		var d := _enemy.global_position.distance_to(p.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = p
	return closest


func get_state() -> State:
	return _state


func get_boss_phase() -> int:
	return _boss_phase
