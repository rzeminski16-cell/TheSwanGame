extends Node
class_name NetworkSyncComponent
## NetworkSyncComponent — Syncs position, health, and animation state across peers.
## Attached to Player node. Owner sends state, others receive.
## Position uses unreliable (high frequency), health/anim uses reliable.

const SYNC_INTERVAL := 1.0 / 20.0  # 20 Hz position sync

var _sync_timer: float = 0.0
var _owner_peer_id: int = 1
var _is_local: bool = true

# Interpolation for remote players
var _target_position: Vector2 = Vector2.ZERO
var _interpolation_speed: float = 15.0


func _ready() -> void:
	set_process(false)
	set_physics_process(false)


func setup(peer_id: int) -> void:
	## Called after player is added to scene. peer_id = owning peer.
	_owner_peer_id = peer_id

	if not GameState.is_multiplayer:
		_is_local = true
		return

	_is_local = (peer_id == multiplayer.get_unique_id())
	_target_position = get_parent().position
	set_process(true)
	set_physics_process(not _is_local)


func _process(delta: float) -> void:
	if not GameState.is_multiplayer:
		return

	if _is_local:
		# Send position at fixed rate
		_sync_timer += delta
		if _sync_timer >= SYNC_INTERVAL:
			_sync_timer = 0.0
			_send_position.rpc(get_parent().position)


func _physics_process(delta: float) -> void:
	if not GameState.is_multiplayer or _is_local:
		return

	# Interpolate remote player toward target position
	var parent := get_parent() as Node2D
	if parent:
		parent.position = parent.position.lerp(_target_position, _interpolation_speed * delta)


# --- Position Sync (unreliable, high frequency) ---

@rpc("any_peer", "call_remote", "unreliable")
func _send_position(pos: Vector2) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if sender != _owner_peer_id:
		return  # Reject spoofed position
	_target_position = pos


# --- Health Sync (reliable, on change) ---

func sync_health(current: float, maximum: float) -> void:
	## Called by HealthComponent when health changes. Only owner sends.
	if not GameState.is_multiplayer or not _is_local:
		return
	_receive_health.rpc(current, maximum)


@rpc("any_peer", "call_remote", "reliable")
func _receive_health(current: float, maximum: float) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if sender != _owner_peer_id:
		return
	var hc = get_parent().get_node_or_null("HealthComponent")
	if hc:
		hc.max_health = maximum
		hc.current_health = current
		hc.health_changed.emit(current, maximum)
		if current <= 0.0 and not hc.is_dead:
			hc.is_dead = true
			hc.died.emit()


# --- Animation/Velocity Sync (reliable) ---

func sync_velocity(vel: Vector2) -> void:
	## Called by player to sync movement direction for animation.
	if not GameState.is_multiplayer or not _is_local:
		return
	_receive_velocity.rpc(vel)


@rpc("any_peer", "call_remote", "unreliable")
func _receive_velocity(vel: Vector2) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if sender != _owner_peer_id:
		return
	var parent := get_parent() as CharacterBody2D
	if parent:
		parent.velocity = vel
